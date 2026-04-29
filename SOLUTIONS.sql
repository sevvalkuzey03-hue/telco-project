-- ============================================================
-- SOLUTIONS.sql
-- Functional SQL answers aligned with CSV structure
-- ============================================================

-- 1.1 Customers subscribed to 'Kobiye Destek' tariff
-- In this query, the customer table is joined with the tariff table to identify the package of each customer.
-- Then a filter is applied for the tariff name 'Kobiye Destek' to narrow the result set to relevant customers.
-- Finally, a readable ordered list is returned with customer name, city, and signup date.
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


-- 1.2 The newest customer subscribed to this tariff
-- This solution uses the same tariff filter but the goal is to return only the most recently registered customer.
-- In Oracle, signup date is sorted descending and only the first row is fetched to safely select the latest record.
-- In case of equal dates, customer_id is used as a secondary sort key for deterministic output.
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


-- 2.1 Tariff distribution among customers
-- This query uses grouped counting to show how many customers are subscribed to each tariff.
-- A LEFT JOIN is preferred so tariffs with zero customers still appear in the report for complete analysis.
-- Results are sorted by customer count descending so the most common tariffs are listed first.
SELECT
    t.tariff_id,
    t.name AS tariff_name,
    COUNT(c.customer_id) AS customer_count
FROM tariffs t
LEFT JOIN customers c ON c.tariff_id = t.tariff_id
GROUP BY t.tariff_id, t.name
ORDER BY customer_count DESC, t.name;


-- 3.1 Oldest registered customers
-- The critical point is evaluating by earliest signup date instead of the lowest customer ID.
-- First, the global minimum signup_date is found, then all customers with that date are returned.
-- This ensures that if multiple customers signed up on the same day, all of them are included.
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


-- 3.2 City distribution of the oldest customers
-- This analysis reuses the oldest-customer set from the previous query as a CTE.
-- Then it groups by city to calculate how many of those first customers belong to each city.
-- Results are sorted by count descending so city concentration can be compared directly.
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


-- 4.1 Customers with missing monthly records
-- In this dataset, MONTHLY_STATS contains one row per customer for the current month, but some customer_id values are missing.
-- Therefore, all IDs in CUSTOMERS are compared with customer_id values in MONTHLY_STATS to detect missing ones.
-- The LEFT JOIN + IS NULL pattern provides a readable and efficient missing-record check.
SELECT
    c.customer_id
FROM customers c
LEFT JOIN monthly_stats ms
       ON ms.customer_id = c.customer_id
WHERE ms.customer_id IS NULL
ORDER BY c.customer_id;


-- 4.2 City distribution of missing customers
-- In this solution, the missing customer set is first extracted in a CTE using the same logic as 4.1.
-- In the next step, this list is grouped by city and counted.
-- This clearly shows in which cities the data entry issue is concentrated.
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


-- 5.1 Customers who used at least 75% of data limit
-- Here, the usage table is joined with customer and tariff tables so the package limits are accessible per row.
-- The usage ratio is calculated as used data divided by data limit, and rows above the 75% threshold are filtered.
-- NULLIF is used to prevent division-by-zero errors for tariffs with zero data limit.
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


-- 5.2 Customers who consumed all package limits (data, minutes, SMS)
-- This query checks whether all three resources reach their limits in the same record.
-- Using the >= operator includes both exactly-at-limit and over-limit usage, which is more realistic.
-- As a result, customers showing full package consumption behavior are listed for analytics.
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


-- 6.1 Customers with unpaid fees
-- In this dataset, financial status is stored in the PAYMENT_STATUS column inside MONTHLY_STATS.
-- Since unpaid or delayed fees are represented by 'UNPAID' and 'LATE', these two values are filtered.
-- The output includes customer information and status to support follow-up operations.
SELECT
    c.customer_id,
    c.name,
    c.city,
    ms.payment_status
FROM monthly_stats ms
JOIN customers c ON c.customer_id = ms.customer_id
WHERE ms.payment_status IN ('UNPAID', 'LATE')
ORDER BY ms.payment_status, c.customer_id;


-- 6.2 Distribution of payment statuses by tariff
-- First, monthly status rows are linked to customers and then to tariffs to identify the tariff for each payment status record.
-- Then grouped counts are calculated by tariff and payment status.
-- This helps detect patterns, for example if one tariff has a high UNPAID ratio and needs action.
SELECT
    t.name AS tariff_name,
    ms.payment_status,
    COUNT(*) AS status_count
FROM monthly_stats ms
JOIN customers c ON c.customer_id = ms.customer_id
JOIN tariffs t ON t.tariff_id = c.tariff_id
GROUP BY t.name, ms.payment_status
ORDER BY t.name, ms.payment_status;

