-- ============================================================
-- TABLE_CREATION_SCRIPTS.sql
-- Oracle XE schema aligned with:
--   CUSTOMERS.csv, MONTHLY_STATS.csv, TARIFFS.csv
-- ============================================================

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE monthly_stats CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE customers CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE tariffs CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

CREATE TABLE tariffs (
    tariff_id       NUMBER PRIMARY KEY,
    name            VARCHAR2(100) NOT NULL,
    monthly_fee     NUMBER(10,2) NOT NULL,
    data_limit      NUMBER(12,2) NOT NULL,
    minute_limit    NUMBER(10) NOT NULL,
    sms_limit       NUMBER(10) NOT NULL,
    CONSTRAINT uq_tariffs_name UNIQUE (name),
    CONSTRAINT chk_tariffs_monthly_fee CHECK (monthly_fee >= 0),
    CONSTRAINT chk_tariffs_data_limit CHECK (data_limit >= 0),
    CONSTRAINT chk_tariffs_minute_limit CHECK (minute_limit >= 0),
    CONSTRAINT chk_tariffs_sms_limit CHECK (sms_limit >= 0)
);

CREATE TABLE customers (
    customer_id     NUMBER PRIMARY KEY,
    name            VARCHAR2(100) NOT NULL,
    city            VARCHAR2(100) NOT NULL,
    signup_date     DATE NOT NULL,
    tariff_id       NUMBER NOT NULL,
    CONSTRAINT fk_customers_tariff
        FOREIGN KEY (tariff_id) REFERENCES tariffs(tariff_id)
);

CREATE TABLE monthly_stats (
    id              NUMBER PRIMARY KEY,
    customer_id     NUMBER NOT NULL,
    data_usage      NUMBER(12,2) DEFAULT 0 NOT NULL,
    minute_usage    NUMBER(10) DEFAULT 0 NOT NULL,
    sms_usage       NUMBER(10) DEFAULT 0 NOT NULL,
    payment_status  VARCHAR2(20) NOT NULL,
    CONSTRAINT fk_monthly_stats_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT uq_monthly_stats_customer UNIQUE (customer_id),
    CONSTRAINT chk_monthly_stats_data_usage CHECK (data_usage >= 0),
    CONSTRAINT chk_monthly_stats_minute_usage CHECK (minute_usage >= 0),
    CONSTRAINT chk_monthly_stats_sms_usage CHECK (sms_usage >= 0),
    CONSTRAINT chk_monthly_stats_payment_status CHECK (payment_status IN ('PAID', 'LATE', 'UNPAID'))
);

CREATE INDEX idx_customers_tariff_id ON customers(tariff_id);
CREATE INDEX idx_customers_city ON customers(city);
CREATE INDEX idx_customers_signup_date ON customers(signup_date);
CREATE INDEX idx_monthly_stats_customer_id ON monthly_stats(customer_id);
CREATE INDEX idx_monthly_stats_payment_status ON monthly_stats(payment_status);

