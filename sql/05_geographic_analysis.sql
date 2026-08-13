-- =====================================================
-- E-COMMERCE CUSTOMER & SALES ANALYTICS
-- 05 - GEOGRAPHIC ANALYSIS
-- =====================================================


-- Revenue Performance by Country
-- Measures each country's contribution to total gross revenue.

SELECT
    country,

    COUNT(DISTINCT invoice) AS orders,

    COUNT(DISTINCT customer_id) AS identified_customers,

    ROUND(
        SUM(line_revenue)::numeric,
        2
    ) AS gross_revenue_gbp,

    ROUND(
        (
            SUM(line_revenue)
            / SUM(SUM(line_revenue)) OVER ()
            * 100
        )::numeric,
        2
    ) AS revenue_pct

FROM clean_sales

GROUP BY country

ORDER BY gross_revenue_gbp DESC;


-- Top International Markets
-- Excludes the United Kingdom to provide a clearer view
-- of performance across international markets.

SELECT
    country,

    COUNT(DISTINCT invoice) AS orders,

    COUNT(DISTINCT customer_id) AS identified_customers,

    ROUND(
        SUM(line_revenue)::numeric,
        2
    ) AS gross_revenue_gbp,

    ROUND(
        SUM(line_revenue)::numeric
        / COUNT(DISTINCT invoice),
        2
    ) AS average_order_value_gbp

FROM clean_sales

WHERE country <> 'United Kingdom'

GROUP BY country

ORDER BY gross_revenue_gbp DESC

LIMIT 15;


-- International Market Revenue Share
-- Calculates each country's share of international revenue
-- after excluding the retailer's domestic UK market.

SELECT
    country,

    ROUND(
        SUM(line_revenue)::numeric,
        2
    ) AS gross_revenue_gbp,

    ROUND(
        (
            SUM(line_revenue)
            / SUM(SUM(line_revenue)) OVER ()
            * 100
        )::numeric,
        2
    ) AS international_revenue_pct

FROM clean_sales

WHERE country <> 'United Kingdom'

GROUP BY country

ORDER BY gross_revenue_gbp DESC

LIMIT 15;
