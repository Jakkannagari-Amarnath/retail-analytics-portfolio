-- ============================================================
-- schema.sql
-- Retail Analytics Portfolio — Table Schema
-- Dataset: Online Retail (UK-based online store, 2009–2011)
-- Source structure matches the Python RFM analysis in this repo
-- ============================================================

CREATE TABLE transactions (
    invoice_no      VARCHAR(20)     NOT NULL,   -- Invoice number; prefix 'C' indicates a cancellation
    stock_code      VARCHAR(20)     NOT NULL,   -- Product/item code
    description     VARCHAR(255),               -- Product description
    quantity        INTEGER         NOT NULL,   -- Units per transaction line (negative = return)
    invoice_date    TIMESTAMP       NOT NULL,   -- Date and time of transaction
    unit_price      DECIMAL(10, 2)  NOT NULL,   -- Price per unit, in GBP
    customer_id     INTEGER,                    -- Nullable: some transactions have no linked customer
    country         VARCHAR(50)     NOT NULL    -- Customer's country
);

CREATE INDEX idx_transactions_customer   ON transactions (customer_id);
CREATE INDEX idx_transactions_invoice    ON transactions (invoice_no);
CREATE INDEX idx_transactions_date       ON transactions (invoice_date);
CREATE INDEX idx_transactions_country    ON transactions (country);
