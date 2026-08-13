-- =====================================================
-- E-COMMERCE CUSTOMER & SALES ANALYTICS
-- 01 - DATA QUALITY & EXPLORATION
-- =====================================================

-- Dataset Overview
SELECT
    COUNT(*) AS total_transaction_rows,
    COUNT(DISTINCT invoice) AS unique_invoices,
    COUNT(DISTINCT stock_code) AS unique_products,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT country) AS unique_countries,
    MIN(invoice_date) AS first_transaction,
    MAX(invoice_date) AS last_transaction
FROM raw_transactions;


-- Missing Value Analysis
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(invoice) AS missing_invoice,
    COUNT(*) - COUNT(stock_code) AS missing_stock_code,
    COUNT(*) - COUNT(description) AS missing_description,
    COUNT(*) - COUNT(quantity) AS missing_quantity,
    COUNT(*) - COUNT(invoice_date) AS missing_invoice_date,
    COUNT(*) - COUNT(price) AS missing_price,
    COUNT(*) - COUNT(customer_id) AS missing_customer_id,
    COUNT(*) - COUNT(country) AS missing_country
FROM raw_transactions;


-- Identify Unusual Quantity and Price Values
SELECT
    COUNT(*) FILTER (WHERE quantity < 0) AS negative_quantity_rows,
    COUNT(*) FILTER (WHERE quantity = 0) AS zero_quantity_rows,
    COUNT(*) FILTER (WHERE price < 0) AS negative_price_rows,
    COUNT(*) FILTER (WHERE price = 0) AS zero_price_rows,
    MIN(quantity) AS minimum_quantity,
    MAX(quantity) AS maximum_quantity,
    MIN(price) AS minimum_price,
    MAX(price) AS maximum_price
FROM raw_transactions;


-- Classify Negative Quantities
SELECT
    COUNT(*) AS negative_quantity_rows,

    COUNT(*) FILTER (
        WHERE invoice LIKE 'C%'
    ) AS cancellation_rows,

    COUNT(*) FILTER (
        WHERE invoice NOT LIKE 'C%'
    ) AS other_negative_rows

FROM raw_transactions
WHERE quantity < 0;


-- Investigate Negative Prices
SELECT
    invoice,
    stock_code,
    description,
    quantity,
    invoice_date,
    price,
    customer_id,
    country
FROM raw_transactions
WHERE price < 0
ORDER BY price;


-- Categorize Zero-Price Transactions
SELECT
    COUNT(*) AS zero_price_rows,

    COUNT(*) FILTER (
        WHERE quantity > 0
    ) AS positive_quantity_rows,

    COUNT(*) FILTER (
        WHERE quantity < 0
    ) AS negative_quantity_rows,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS missing_customer_rows,

    COUNT(*) FILTER (
        WHERE customer_id IS NOT NULL
    ) AS identified_customer_rows

FROM raw_transactions
WHERE price = 0;


-- Identify Exact Duplicate Records
WITH duplicate_groups AS (
    SELECT
        invoice,
        stock_code,
        description,
        quantity,
        invoice_date,
        price,
        customer_id,
        country,
        COUNT(*) AS row_count
    FROM raw_transactions
    GROUP BY
        invoice,
        stock_code,
        description,
        quantity,
        invoice_date,
        price,
        customer_id,
        country
    HAVING COUNT(*) > 1
)

SELECT
    COUNT(*) AS duplicate_groups,
    SUM(row_count) AS rows_in_duplicate_groups,
    SUM(row_count - 1) AS excess_duplicate_rows
FROM duplicate_groups;


-- Estimate Revenue Impact of Potential Exact Duplicates
WITH numbered_transactions AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                invoice,
                stock_code,
                description,
                quantity,
                invoice_date,
                price,
                customer_id,
                country
            ORDER BY invoice
        ) AS duplicate_number
    FROM raw_transactions
),

original_sales AS (
    SELECT
        SUM(quantity * price) AS original_revenue
    FROM raw_transactions
    WHERE quantity > 0
        AND price > 0
        AND invoice NOT LIKE 'C%'
),

deduplicated_sales AS (
    SELECT
        SUM(quantity * price) AS deduplicated_revenue
    FROM numbered_transactions
    WHERE duplicate_number = 1
        AND quantity > 0
        AND price > 0
        AND invoice NOT LIKE 'C%'
)

SELECT
    ROUND(original_revenue::numeric, 2) AS original_revenue_gbp,
    ROUND(deduplicated_revenue::numeric, 2) AS deduplicated_revenue_gbp,
    ROUND(
        (original_revenue - deduplicated_revenue)::numeric,
        2
    ) AS potential_duplicate_revenue_gbp,
    ROUND(
        (
            (original_revenue - deduplicated_revenue)
            / original_revenue * 100
        )::numeric,
        2
    ) AS potential_duplicate_revenue_pct
FROM original_sales, deduplicated_sales;


-- Create Clean Sales View
-- Keeps positive, non-cancelled, revenue-generating transactions.
-- Raw data remains unchanged.

CREATE OR REPLACE VIEW clean_sales AS
SELECT
    invoice,
    stock_code,
    description,
    quantity,
    invoice_date,
    price,
    customer_id,
    country,
    quantity * price AS line_revenue
FROM raw_transactions
WHERE quantity > 0
    AND price > 0
    AND invoice NOT LIKE 'C%';


-- Validate Clean Sales View
SELECT
    COUNT(*) AS clean_rows,
    COUNT(DISTINCT invoice) AS total_orders,
    COUNT(DISTINCT customer_id) AS identified_customers,
    COUNT(DISTINCT stock_code) AS unique_products,
    MIN(invoice_date) AS first_sale,
    MAX(invoice_date) AS last_sale,
    ROUND(SUM(line_revenue), 2) AS gross_revenue_gbp
FROM clean_sales;

-- Add data quality analysis
