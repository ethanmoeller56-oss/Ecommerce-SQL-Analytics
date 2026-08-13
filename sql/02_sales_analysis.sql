-- =====================================================
-- E-COMMERCE CUSTOMER & SALES ANALYTICS
-- 02 - SALES PERFORMANCE ANALYSIS
-- =====================================================


-- Core Sales KPIs

SELECT
    ROUND(SUM(line_revenue), 2) AS gross_revenue_gbp,
    COUNT(DISTINCT invoice) AS total_orders,
    SUM(quantity) AS units_sold,

    ROUND(
        SUM(line_revenue)
        / COUNT(DISTINCT invoice),
        2
    ) AS average_order_value_gbp,

    ROUND(
        SUM(line_revenue)
        / SUM(quantity),
        2
    ) AS average_revenue_per_unit_gbp

FROM clean_sales;


-- Monthly Sales Performance

SELECT
    DATE_TRUNC('month', invoice_date) AS sales_month,
    ROUND(SUM(line_revenue), 2) AS gross_revenue_gbp,
    COUNT(DISTINCT invoice) AS orders,
    SUM(quantity) AS units_sold,

    ROUND(
        SUM(line_revenue)
        / COUNT(DISTINCT invoice),
        2
    ) AS average_order_value_gbp

FROM clean_sales

GROUP BY DATE_TRUNC('month', invoice_date)

ORDER BY sales_month;


-- Month-over-Month Revenue Growth

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', invoice_date) AS sales_month,
        SUM(line_revenue) AS revenue_gbp

    FROM clean_sales

    GROUP BY DATE_TRUNC('month', invoice_date)
),

monthly_growth AS (
    SELECT
        sales_month,
        revenue_gbp,

        LAG(revenue_gbp) OVER (
            ORDER BY sales_month
        ) AS previous_month_revenue_gbp

    FROM monthly_sales
)

SELECT
    sales_month,

    ROUND(
        revenue_gbp,
        2
    ) AS revenue_gbp,

    ROUND(
        previous_month_revenue_gbp,
        2
    ) AS previous_month_revenue_gbp,

    ROUND(
        (
            (revenue_gbp - previous_month_revenue_gbp)
            / NULLIF(previous_month_revenue_gbp, 0)
            * 100
        )::numeric,
        2
    ) AS month_over_month_growth_pct

FROM monthly_growth

ORDER BY sales_month;


-- Year-over-Year Monthly Revenue Growth

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', invoice_date) AS sales_month,
        SUM(line_revenue) AS revenue_gbp

    FROM clean_sales

    GROUP BY DATE_TRUNC('month', invoice_date)
),

yearly_comparison AS (
    SELECT
        sales_month,
        revenue_gbp,

        LAG(revenue_gbp, 12) OVER (
            ORDER BY sales_month
        ) AS previous_year_revenue_gbp

    FROM monthly_sales
)

SELECT
    sales_month,

    ROUND(
        revenue_gbp,
        2
    ) AS revenue_gbp,

    ROUND(
        previous_year_revenue_gbp,
        2
    ) AS previous_year_revenue_gbp,

    ROUND(
        (
            (revenue_gbp - previous_year_revenue_gbp)
            / NULLIF(previous_year_revenue_gbp, 0)
            * 100
        )::numeric,
        2
    ) AS year_over_year_growth_pct

FROM yearly_comparison

WHERE previous_year_revenue_gbp IS NOT NULL

ORDER BY sales_month;
