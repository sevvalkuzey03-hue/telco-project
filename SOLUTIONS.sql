-- ============================================================
-- SOLUTIONS.sql
-- Functional SQL answers aligned with CSV structure
-- ============================================================

-- 1.1 'Kobiye Destek' tarifesine abone olan müşteriler
-- Bu sorguda önce müşteri tablosu ile tarife tablosu eşleştirilir ve her müşterinin bağlı olduğu paket bulunur.
-- Ardından sadece 'Kobiye Destek' isimli tarife için filtre uygulanarak ilgili müşteri kümesi daraltılır.
-- Son olarak okunabilir bir çıktı için müşteri adı, şehir ve kayıt tarihi ile birlikte sıralı bir liste döndürülür.
SELECT
    c.customer_id,
    c.name,
    c.city,
    c.signup_date,
    t.name AS tariff_name
FROM customers c
JOIN tariffs t ON t.tariff_id = c.tariff_id
WHERE t.name = 'Kobiye Destek'
ORDER BY c.signup_date DESC, c.customer_id;


-- 1.2 Bu tarifeye abone olan en yeni müşteri
-- Bu çözümde yine aynı tarife filtresi kullanılır ancak hedef sadece en son kayıtlanan müşteridir.
-- Oracle'da en güncel tarihi güvenli şekilde almak için kayıt tarihi azalan sıralanır ve ilk satır çekilir.
-- Eşit tarih durumunda tutarlı sonuç almak için customer_id ikincil sıralama anahtarı olarak kullanılır.
SELECT
    c.customer_id,
    c.name,
    c.city,
    c.signup_date
FROM customers c
JOIN tariffs t ON t.tariff_id = c.tariff_id
WHERE t.name = 'Kobiye Destek'
ORDER BY c.signup_date DESC, c.customer_id DESC
FETCH FIRST 1 ROW ONLY;


-- 2.1 Müşteriler arasında tarifelerin dağılımı
-- Bu sorgu, her tarifeye kaç müşterinin bağlı olduğunu göstermek için grup bazlı sayım yaklaşımı kullanır.
-- LEFT JOIN tercih edilerek henüz müşterisi olmayan tarifeler de raporda görünür ve analiz eksiksiz olur.
-- Toplam müşteri adedi azalan sıralanarak en yaygın tarifeler ilk satırlarda sunulur.
SELECT
    t.tariff_id,
    t.name AS tariff_name,
    COUNT(c.customer_id) AS customer_count
FROM tariffs t
LEFT JOIN customers c ON c.tariff_id = t.tariff_id
GROUP BY t.tariff_id, t.name
ORDER BY customer_count DESC, t.name;


-- 3.1 Kayıt olan en eski müşteriler
-- Buradaki kritik nokta en düşük ID yerine en eski kayıt tarihine göre değerlendirme yapmaktır.
-- Önce global minimum signup_date değeri bulunur, sonra bu tarihe sahip tüm müşteriler döndürülür.
-- Böylece aynı gün birden fazla müşteri kaydolduysa hepsi eksiksiz biçimde sonuçta yer alır.
SELECT
    c.customer_id,
    c.name,
    c.city,
    c.signup_date
FROM customers c
WHERE c.signup_date = (
    SELECT MIN(c2.signup_date)
    FROM customers c2
)
ORDER BY c.customer_id;


-- 3.2 En eski müşterilerin şehir dağılımı
-- Bu analiz bir önceki sorgudaki en eski müşteri kümesini alt sorgu/CTE olarak tekrar kullanır.
-- Ardından şehir bazında gruplanarak her şehirde kaç adet ilk müşteri olduğu hesaplanır.
-- Sonuçlar adet azalan sıralandığı için şehir yoğunluğu doğrudan kıyaslanabilir.
WITH first_customers AS (
    SELECT
        c.customer_id,
        c.city
    FROM customers c
    WHERE c.signup_date = (
        SELECT MIN(c2.signup_date)
        FROM customers c2
    )
)
SELECT
    fc.city,
    COUNT(*) AS first_customer_count
FROM first_customers fc
GROUP BY fc.city
ORDER BY first_customer_count DESC, fc.city;


-- 4.1 Aylık kaydı eksik müşteriler
-- Bu veri setinde MONTHLY_STATS her müşteri için bu aya ait tek satır içerir ve bazı customer_id değerleri eksiktir.
-- Bu nedenle müşteri tablosundaki tüm ID'ler ile MONTHLY_STATS içindeki customer_id kümesi karşılaştırılarak eksikler bulunur.
-- LEFT JOIN + IS NULL paterni kullanıldığı için hem performanslı hem de okunabilir bir eksik kayıt kontrolü elde edilir.
SELECT
    c.customer_id
FROM customers c
LEFT JOIN monthly_stats ms
       ON ms.customer_id = c.customer_id
WHERE ms.customer_id IS NULL
ORDER BY c.customer_id;


-- 4.2 Eksik müşterilerin şehir dağılımı
-- Bu çözümde önce eksik müşteri kümesi 4.1 ile aynı mantıkta CTE içinde çıkarılır.
-- Sonraki aşamada bu müşteri listesi şehir bilgisiyle birleştirilir ve şehir bazında sayılır.
-- Böylece veri giriş hatasının hangi şehirlerde yoğunlaştığı operasyon ekiplerine net bir şekilde raporlanabilir.
WITH missing_customers AS (
    SELECT
        c.customer_id,
        c.city
    FROM customers c
    LEFT JOIN monthly_stats ms
           ON ms.customer_id = c.customer_id
    WHERE ms.customer_id IS NULL
)
SELECT
    mc.city,
    COUNT(*) AS missing_customer_count
FROM missing_customers mc
GROUP BY mc.city
ORDER BY missing_customer_count DESC, mc.city;


-- 5.1 Veri limitinin en az %75'ini kullanan müşteriler
-- Burada kullanım tablosu ile müşteri-tarife zinciri birleştirilerek her satırda kullanıcının paket limiti erişilebilir hale getirilir.
-- Kullanım oranı, kullanılan veri / paket veri limiti formülüyle hesaplanır ve yüzde 75 eşiği filtrelenir.
-- Sıfıra bölme riskini önlemek için NULLIF kullanılarak veri limiti 0 olan anomaliler güvenli şekilde ele alınır.
SELECT
    c.customer_id,
    c.name,
    ms.data_usage,
    t.data_limit,
    ROUND((ms.data_usage / NULLIF(t.data_limit, 0)) * 100, 2) AS data_usage_pct
FROM monthly_stats ms
JOIN customers c ON c.customer_id = ms.customer_id
JOIN tariffs t ON t.tariff_id = c.tariff_id
WHERE (ms.data_usage / NULLIF(t.data_limit, 0)) >= 0.75
ORDER BY data_usage_pct DESC, c.customer_id;


-- 5.2 Veri, dakika ve SMS limitlerinin tamamını tüketen müşteriler
-- Bu sorgu tek bir kayıtta üç kaynağın da limite ulaşıp ulaşmadığını aynı anda kontrol eder.
-- Karşılaştırma operatörü olarak >= kullanılması, limiti aşan kullanımları da dahil ederek daha gerçekçi bir yakalama sağlar.
-- Sonuçta hedef ay bazlı olarak tam tüketim davranışı gösteren müşteriler analitik ekip için listelenir.
SELECT
    c.customer_id,
    c.name,
    ms.data_usage,
    ms.minute_usage,
    ms.sms_usage
FROM monthly_stats ms
JOIN customers c ON c.customer_id = ms.customer_id
JOIN tariffs t ON t.tariff_id = c.tariff_id
WHERE ms.data_usage >= t.data_limit
  AND ms.minute_usage >= t.minute_limit
  AND ms.sms_usage >= t.sms_limit
ORDER BY c.customer_id;


-- 6.1 Ödenmemiş ücreti olan müşteriler
-- Bu veri setinde finansal durum MONTHLY_STATS içindeki PAYMENT_STATUS alanında tutulur.
-- Ödenmemiş veya gecikmiş ücretleri temsil eden durumlar 'UNPAID' ve 'LATE' olduğundan bu iki değer filtrelenir.
-- Çıktıda müşteri bilgisiyle birlikte durum bilgisi verilerek takip ekiplerinin aksiyon alması kolaylaştırılır.
SELECT
    c.customer_id,
    c.name,
    c.city,
    ms.payment_status
FROM monthly_stats ms
JOIN customers c ON c.customer_id = ms.customer_id
WHERE ms.payment_status IN ('UNPAID', 'LATE')
ORDER BY ms.payment_status, c.customer_id;


-- 6.2 Ödeme durumlarının tarifelere göre dağılımı
-- Önce ödeme kaydı müşteriye, müşteri de tarifeye bağlanarak her ödeme satırının hangi tarifeye ait olduğu bulunur.
-- Sonra tarife ve ödeme durumu kırılımında gruplama yapılarak adet bazlı dağılım elde edilir.
-- Bu yapı, örneğin belirli bir tarifede UNPAID oranı yüksekse kampanya veya tahsilat stratejisi geliştirmek için kullanılabilir.
SELECT
    t.name AS tariff_name,
    ms.payment_status,
    COUNT(*) AS status_count
FROM monthly_stats ms
JOIN customers c ON c.customer_id = ms.customer_id
JOIN tariffs t ON t.tariff_id = c.tariff_id
GROUP BY t.name, ms.payment_status
ORDER BY t.name, ms.payment_status;

