-- =====================================================
-- E-COMMERCE CUSTOMER & SALES ANALYTICS
-- 04 - CUSTOMER ANALYSIS
-- =====================================================


-- Top Customers by Gross Revenue

SELECT
    customer_id,
    COUNT(DISTINCT invoice) AS total_orders,
    SUM(quantity) AS units_purchased,

    ROUND(
        SUM(quantity * price)::numeric,
        2
    ) AS gross_revenue_gbp,

    ROUND(
        SUM(quantity * price)::numeric
        / COUNT(DISTINCT invoice),
        2
    ) AS average_order_value_gbp

FROM raw_transactions

WHERE quantity > 0
    AND price > 0
    AND invoice NOT LIKE 'C%'
    AND customer_id IS NOT NULL

GROUP BY customer_id

ORDER BY gross_revenue_gbp DESC

LIMIT 20;


-- Identified vs. Unidentified Customer Revenue

SELECT
    CASE
        WHEN customer_id IS NULL
            THEN 'Unidentified Customer'
        ELSE 'Identified Customer'
    END AS customer_status,

    COUNT(DISTINCT invoice) AS orders,

    ROUND(
        SUM(quantity * price)::numeric,
        2
    ) AS gross_revenue_gbp,

    ROUND(
        (
            SUM(quantity * price)
            / SUM(SUM(quantity * price)) OVER ()
            * 100
        )::numeric,
        2
    ) AS revenue_pct

FROM raw_transactions

WHERE quantity > 0
    AND price > 0
    AND invoice NOT LIKE 'C%'

GROUP BY customer_status

ORDER BY gross_revenue_gbp DESC;


-- Create Reusable RFM Customer Segments View
-- Recency: days since most recent positive purchase
-- Frequency: number of distinct positive purchase invoices
-- Monetary: net customer revenue after cancellations

CREATE OR REPLACE VIEW rfm_customer_segments AS

WITH customer_rfm AS (
    SELECT
        customer_id,

        DATE '2011-12-10'
            - MAX(
                CASE
                    WHEN quantity > 0
                        AND price > 0
                        AND invoice NOT LIKE 'C%'
                    THEN invoice_date::date
                END
            ) AS recency_days,

        COUNT(
            DISTINCT CASE
                WHEN quantity > 0
                    AND price > 0
                    AND invoice NOT LIKE 'C%'
                THEN invoice
            END
        ) AS frequency,

        ROUND(
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
            )::numeric,
            2
        ) AS monetary_value_gbp

    FROM raw_transactions

    WHERE customer_id IS NOT NULL

    GROUP BY customer_id
),

rfm_scores AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary_value_gbp,

        NTILE(5) OVER (
            ORDER BY recency_days DESC
        ) AS recency_score,

        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score,

        NTILE(5) OVER (
            ORDER BY monetary_value_gbp ASC
        ) AS monetary_score

    FROM customer_rfm

    WHERE frequency > 0
)

SELECT
    *,

    CASE
        WHEN recency_score >= 4
            AND frequency_score >= 4
            AND monetary_score >= 4
            THEN 'Champions'

        WHEN recency_score >= 3
            AND frequency_score >= 4
            THEN 'Loyal Customers'

        WHEN recency_score >= 4
            AND frequency_score BETWEEN 2 AND 3
            THEN 'Potential Loyalists'

        WHEN recency_score <= 2
            AND frequency_score >= 4
            THEN 'At Risk'

        WHEN recency_score <= 2
            AND frequency_score <= 2
            THEN 'Lost Customers'

        ELSE 'Other'
    END AS customer_segment

FROM rfm_scores;


-- Customer Segment Summary

SELECT
    customer_segment,
    COUNT(*) AS customers,

    ROUND(
        COUNT(*)::numeric
        / SUM(COUNT(*)) OVER ()
        * 100,
        2
    ) AS customer_pct,

    ROUND(
        SUM(monetary_value_gbp),
        2
    ) AS net_revenue_gbp,

    ROUND(
        SUM(monetary_value_gbp)
        / SUM(SUM(monetary_value_gbp)) OVER ()
        * 100,
        2
    ) AS revenue_pct,

    ROUND(
        AVG(monetary_value_gbp),
        2
    ) AS avg_customer_value_gbp

FROM rfm_customer_segments

GROUP BY customer_segment

ORDER BY net_revenue_gbp DESC;


-- Highest-Value At-Risk Customers

SELECT
    customer_id,
    recency_days,
    frequency,
    monetary_value_gbp,
    recency_score,
    frequency_score,
    monetary_score

FROM rfm_customer_segments

WHERE customer_segment = 'At Risk'

ORDER BY monetary_value_gbp DESC

LIMIT 20;


-- Customer Revenue Concentration

WITH customer_revenue AS (
    SELECT
        customer_id,

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

    WHERE customer_id IS NOT NULL

    GROUP BY customer_id
),

ranked_customers AS (
    SELECT
        customer_id,
        net_revenue_gbp,

        ROW_NUMBER() OVER (
            ORDER BY net_revenue_gbp DESC
        ) AS customer_rank,

        COUNT(*) OVER () AS total_customers

    FROM customer_revenue

    WHERE net_revenue_gbp > 0
)

SELECT
    CASE
        WHEN customer_rank <= CEIL(total_customers * 0.01)
            THEN 'Top 1%'

        WHEN customer_rank <= CEIL(total_customers * 0.05)
            THEN 'Top 2-5%'

        WHEN customer_rank <= CEIL(total_customers * 0.20)
            THEN 'Top 6-20%'

        ELSE 'Bottom 80%'
    END AS customer_group,

    COUNT(*) AS customers,

    ROUND(
        SUM(net_revenue_gbp)::numeric,
        2
    ) AS net_revenue_gbp,

    ROUND(
        (
            SUM(net_revenue_gbp)
            / SUM(SUM(net_revenue_gbp)) OVER ()
            * 100
        )::numeric,
        2
    ) AS revenue_pct

FROM ranked_customers

GROUP BY customer_group

ORDER BY net_revenue_gbp DESC;
