# Telco SQL Ödevi (Oracle XE)

Merhaba, bu repoda ödev için hazırladığım dosyalar var.
Amaç: Oracle XE üstünde veritabanını kurup CSV dosyalarını içeri almak ve istenen SQL sorgularını çalıştırmak.

## Bu projede hangi dosyalar var?

- `docker-compose.yml` -> Oracle XE container başlatmak için
- `sql/TABLE_CREATION_SCRIPTS.sql` -> tabloları oluşturmak için
- `sql/SOLUTIONS.sql` -> soruların SQL cevapları için

## 1) Oracle'ı Docker ile ayağa kaldırma

Bilgisayarda Docker Desktop kurulu olmalı.

Terminalde proje klasöründe şunu çalıştır:

```bash
docker compose up -d
```

Kontrol etmek için:

```bash
docker ps
docker logs -f telco-oracle-xe
```

Bağlantı bilgileri:

- Host: `localhost`
- Port: `1521`
- Service Name: `XEPDB1`
- User: `telco_user`
- Password: `telco_pass`

Not: Container ilk açılırken `TABLE_CREATION_SCRIPTS.sql` otomatik çalışır.

## 2) DBeaver ile bağlanma

1. DBeaver aç
2. `New Database Connection` de
3. `Oracle` seç
4. Yukarıdaki bağlantı bilgilerini gir
5. `Test Connection` yap
6. Sonra kaydet

## 3) CSV dosyalarını içeri aktarma

Kullanılan dosyalar:

- `TARIFFS.csv`
- `CUSTOMERS.csv`
- `MONTHLY_STATS.csv`

Sıra önemli, şu sırayla import et:

1. `tariffs`
2. `customers`
3. `monthly_stats`

Import adımı:

- İlgili tabloya sağ tık
- `Import Data`
- CSV seç
- Kolon eşleşmelerini kontrol et

Önemli not:

- `CUSTOMERS.csv` içindeki `SIGNUP_DATE` için format `DD/MM/YYYY` olmalı
- `MONTHLY_STATS.csv` içindeki `PAYMENT_STATUS` değerleri: `PAID`, `LATE`, `UNPAID`

## 4) Sorguları çalıştırma

1. DBeaver SQL Editor'da `sql/SOLUTIONS.sql` dosyasını aç
2. Sorguları sırayla çalıştır
3. Çıktıların ekran görüntüsünü al

## 5) Kısa kontrol listesi

- [x] Tablo scripti hazır
- [x] Sorgu scripti hazır
- [x] Docker ile ortam açılıyor
- [ ] CSV import yapıldı
- [ ] Sorgu sonuç ekran görüntüleri alındı

## 6) Ekran görüntüsü isim önerisi

`docs/` klasörüne şu şekilde koyabilirsin:

- `docs/01-docker-running.png`
- `docs/02-dbeaver-connection-test.png`
- `docs/03-import-tariffs.png`
- `docs/04-import-customers.png`
- `docs/05-import-monthly-stats.png`
- `docs/06-query-results.png`

