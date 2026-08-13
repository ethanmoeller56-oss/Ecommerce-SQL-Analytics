-- =====================================================
-- E-COMMERCE CUSTOMER & SALES ANALYTICS
-- 03 - PRODUCT PERFORMANCE ANALYSIS
-- =====================================================


-- Top Products by Gross Revenue
-- Product identity is based on stock_code rather than description
-- because descriptions are not fully standardized in the source data.

SELECT
    stock_code,
    MAX(description) AS sample_description,
    SUM(quantity) AS units_sold,
    ROUND(SUM(line_revenue), 2) AS gross_revenue_gbp,
    COUNT(DISTINCT invoice) AS orders

FROM clean_sales

WHERE description IS NOT NULL
    AND stock_code NOT IN ('M', 'DOT', 'POST')

GROUP BY stock_code

ORDER BY gross_revenue_gbp DESC

LIMIT 20;


-- Top Products by Units Sold

SELECT
    stock_code,
    MAX(description) AS sample_description,
    SUM(quantity) AS units_sold,
    ROUND(SUM(line_revenue), 2) AS gross_revenue_gbp,
    COUNT(DISTINCT invoice) AS orders

FROM clean_sales

WHERE description IS NOT NULL
    AND stock_code NOT IN ('M', 'DOT', 'POST')

GROUP BY stock_code

ORDER BY units_sold DESC

LIMIT 20;


-- Identify the Most Common Description for Each Stock Code

WITH description_counts AS (
    SELECT
        stock_code,
        description,
        COUNT(*) AS description_count

    FROM clean_sales

    WHERE description IS NOT NULL

    GROUP BY
        stock_code,
        description
),

ranked_descriptions AS (
    SELECT
        stock_code,
        description,
        description_count,

        ROW_NUMBER() OVER (
            PARTITION BY stock_code
            ORDER BY description_count DESC
        ) AS description_rank

    FROM description_counts
)

SELECT
    stock_code,
    description AS canonical_description,
    description_count

FROM ranked_descriptions

WHERE description_rank = 1

ORDER BY description_count DESC;


-- Net Product Performance Including Cancellations
-- Positive sales contribute positively.
-- Cancellation invoices beginning with "C" contribute negatively.

WITH description_counts AS (
    SELECT
        stock_code,
        description,
        COUNT(*) AS description_count

    FROM clean_sales

    WHERE description IS NOT NULL

    GROUP BY
        stock_code,
        description
),

ranked_descriptions AS (
    SELECT
        stock_code,
        description,

        ROW_NUMBER() OVER (
            PARTITION BY stock_code
            ORDER BY description_count DESC
        ) AS description_rank

    FROM description_counts
),

canonical_products AS (
    SELECT
        stock_code,
        description AS product_description

    FROM ranked_descriptions

    WHERE description_rank = 1
),

product_performance AS (
    SELECT
        stock_code,

        SUM(
            CASE
                WHEN quantity > 0
                    AND price > 0
                THEN quantity
                ELSE 0
            END
        ) AS gross_units_sold,

        ABS(
            SUM(
                CASE
                    WHEN invoice LIKE 'C%'
                        AND quantity < 0
                        AND price > 0
                    THEN quantity
                    ELSE 0
                END
            )
        ) AS cancelled_units,

        SUM(
            CASE
                WHEN price > 0
                    AND (
                        quantity > 0
                        OR (invoice LIKE 'C%' AND quantity < 0)
                    )
                THEN quantity
                ELSE 0
            END
        ) AS net_units_sold,

        SUM(
            CASE
                WHEN price > 0
                    AND (
                        quantity > 0
                        OR (invoice LIKE 'C%' AND quantity < 0)
                    )
                THEN quantity * price
                ELSE 0
            END
        ) AS net_revenue_gbp

    FROM raw_transactions

    WHERE stock_code NOT IN ('M', 'DOT', 'POST')

    GROUP BY stock_code
)

SELECT
    pp.stock_code,
    cp.product_description,
    pp.gross_units_sold,
    pp.cancelled_units,
    pp.net_units_sold,
    ROUND(pp.net_revenue_gbp::numeric, 2) AS net_revenue_gbp

FROM product_performance AS pp

LEFT JOIN canonical_products AS cp
    ON pp.stock_code = cp.stock_code

ORDER BY pp.net_revenue_gbp DESC

LIMIT 20;


-- Product Cancellation Rate by Units
-- Minimum 1,000 gross units to reduce small-sample distortion.

WITH product_cancellations AS (
    SELECT
        stock_code,

        SUM(
            CASE
                WHEN quantity > 0
                    AND price > 0
                THEN quantity
                ELSE 0
            END
        ) AS gross_units_sold,

        ABS(
            SUM(
                CASE
                    WHEN invoice LIKE 'C%'
                        AND quantity < 0
                        AND price > 0
                    THEN quantity
                    ELSE 0
                END
            )
        ) AS cancelled_units

    FROM raw_transactions

    WHERE stock_code NOT IN ('M', 'DOT', 'POST')

    GROUP BY stock_code
)

SELECT
    stock_code,
    gross_units_sold,
    cancelled_units,

    ROUND(
        cancelled_units::numeric
        / NULLIF(gross_units_sold, 0)
        * 100,
        2
    ) AS cancellation_rate_pct

FROM product_cancellations

WHERE gross_units_sold >= 1000

ORDER BY cancellation_rate_pct DESC

LIMIT 20;


-- Investigate High-Cancellation Products
-- These products showed unusually high cancellation rates.

SELECT
    stock_code,
    invoice,
    description,
    quantity,
    price,
    customer_id,
    invoice_date

FROM raw_transactions

WHERE stock_code IN ('23843', '23166', '84347')
    AND invoice LIKE 'C%'
    AND quantity < 0

ORDER BY
    stock_code,
    quantity ASC;


-- Cancellation Frequency vs. Cancellation Volume

SELECT
    stock_code,
    COUNT(DISTINCT invoice) AS cancellation_orders,
    COUNT(*) AS cancellation_line_items,
    ABS(SUM(quantity)) AS cancelled_units,

    ROUND(
        ABS(AVG(quantity))::numeric,
        2
    ) AS avg_units_per_cancellation_line

FROM raw_transactions

WHERE invoice LIKE 'C%'
    AND quantity < 0
    AND stock_code IN ('23843', '23166', '84347')

GROUP BY stock_code

ORDER BY cancelled_units DESC;
