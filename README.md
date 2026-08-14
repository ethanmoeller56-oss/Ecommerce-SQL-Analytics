# E-Commerce Customer & Sales Analytics

## Project Overview

This project analyzes more than 1 million e-commerce transactions using PostgreSQL to evaluate sales performance, product trends, customer behavior, and geographic markets.

The goal was to build an end-to-end SQL analytics project that moves beyond basic querying and demonstrates how SQL can be used to clean transactional data, investigate data-quality issues, calculate business KPIs, analyze customer behavior, and generate actionable business insights.

The analysis covers transactions from December 2009 through December 2011 for a UK-based online retailer.

---

## Business Questions

The analysis was designed to answer several key business questions:

- How is revenue changing over time?
- Which products generate the most revenue and sales volume?
- How do cancellations affect product performance?
- Who are the company's most valuable customers?
- Which customers may be at risk of becoming inactive?
- How concentrated is revenue among top customers?
- Which international markets generate the most revenue?
- What data-quality issues could affect the reliability of the analysis?

---

## Dataset

The dataset contains 1,067,371 transaction records and includes:

- Invoice number
- Product stock code
- Product description
- Quantity
- Invoice date
- Unit price
- Customer ID
- Country

All monetary values are reported in British pounds (GBP).

The raw CSV is not included in this repository because of its size. Additional information about the dataset, source, schema, and data-quality considerations can be found in [`data/README.md`](data/README.md).

---

## Tools & SQL Skills

**Database:** PostgreSQL  
**Database Management:** pgAdmin

SQL techniques demonstrated throughout the project include:

- Common Table Expressions (CTEs)
- Window functions
- `LAG()`
- `ROW_NUMBER()`
- `NTILE()`
- `PARTITION BY`
- `CASE` statements
- Conditional aggregation
- `JOIN`
- `GROUP BY`
- `HAVING`
- `COUNT(DISTINCT)`
- `DATE_TRUNC()`
- `NULLIF()`
- Type casting
- Views
- RFM customer segmentation

---

## Data Preparation & Quality Analysis

Before performing the business analysis, I investigated the raw transactional data for potential quality issues.

The analysis identified:

- Negative quantities associated primarily with cancellations
- Zero-price transactions
- Negative-price accounting adjustments
- Missing customer IDs
- Inconsistent descriptions for identical stock codes
- Extreme transaction quantities
- Potential duplicate transaction records

### Potential Duplicates

The analysis identified:

- 32,907 groups of identical transaction records
- 34,335 potential excess duplicate rows
- Approximately £496,334 in gross revenue associated with potential excess duplicates
- Potential duplicates represented approximately 2.37% of gross revenue

The source data does not contain a unique transaction-line identifier, making it impossible to reliably distinguish erroneous duplicates from legitimate repeated line items.

Rather than automatically deleting these records, they were retained and documented as a limitation of the analysis.

A reusable `clean_sales` view was created for gross sales analysis containing positive-quantity, positive-price, non-cancellation transactions.

---

# Analysis & Key Findings

## 1. Sales Performance

The cleaned sales dataset contained:

| KPI | Result |
|---|---:|
| Gross Revenue | **£20.97M** |
| Orders | **40,077** |
| Units Sold | **11.42M** |
| Average Order Value | **£523.31** |
| Average Revenue per Unit | **£1.84** |

Monthly revenue analysis revealed clear seasonal patterns.

Sales accelerated substantially during September through November, with November producing approximately:

- £1.47M in November 2010
- £1.51M in November 2011

Year-over-year analysis also showed stronger performance during several months in the second half of 2011, including:

- May: **+16.77%**
- July: **+10.53%**
- August: **+8.87%**
- September: **+14.52%**

> **Note:** December 2011 is a partial month ending December 9 and should not be interpreted as a full-month decline.

---

## 2. Product Performance

Product analysis showed that sales volume and revenue do not necessarily identify the same top-performing products.

For example, `WORLD WAR 2 GLIDERS ASSTD DESIGNS` generated the highest gross unit volume at more than 110,000 units, but only approximately £25K in gross revenue.

In comparison, `REGENCY CAKESTAND 3 TIER` generated substantially lower unit volume but ranked as the highest product by net revenue.

### Top Products by Net Revenue

| Product | Net Revenue |
|---|---:|
| Regency Cakestand 3 Tier | **£327,813.65** |
| White Hanging Heart T-Light Holder | **£253,720.02** |
| Jumbo Bag Red Retrospot | **£181,278.51** |
| Party Bunting | **£147,948.50** |
| Assorted Colour Bird Ornament | **£131,413.85** |

Product descriptions were not consistently standardized in the raw data. To prevent identical products from being treated as separate SKUs, `stock_code` was used as the primary product identifier.

`ROW_NUMBER()` and `PARTITION BY` were then used to identify the most frequently occurring description for each stock code.

### Cancellation Analysis

Several products initially appeared to have unusually high cancellation rates.

Further investigation revealed that these rates were sometimes driven by a small number of extremely large cancellation transactions.

For example:

- Stock code `23843` had 80,995 gross units and 80,995 cancelled units
- The entire cancellation volume came from one cancellation transaction

This demonstrated why aggregate metrics should be investigated before being interpreted as evidence of widespread customer behavior.

---

## 3. Customer Analysis & RFM Segmentation

Approximately 84.60% of gross revenue could be associated with identified customers, providing sufficient coverage for customer-level analysis.

An RFM model was created using:

**Recency** — Days since the customer's most recent purchase  
**Frequency** — Number of distinct purchase orders  
**Monetary Value** — Net revenue generated after cancellations

Customers were scored from 1–5 using PostgreSQL's `NTILE()` window function and assigned to behavioral segments.

### Customer Segments

| Segment | Customers | Customer % | Net Revenue | Revenue % |
|---|---:|---:|---:|---:|
| Champions | 1,297 | 22.07% | £11.67M | 69.85% |
| Loyal Customers | 702 | 11.94% | £1.86M | 11.11% |
| Other | 1,293 | 22.00% | £1.02M | 6.11% |
| At Risk | 351 | 5.97% | £951.7K | 5.70% |
| Potential Loyalists | 705 | 11.99% | £609.5K | 3.65% |
| Lost Customers | 1,530 | 26.03% | £599.5K | 3.59% |

### Key Customer Finding

**Champions represent only 22.07% of customers but generate 69.85% of identified net revenue.

This indicates that customer retention is particularly important because a relatively small portion of the customer base drives the majority of revenue.

---

## 4. At-Risk Customer Analysis

The RFM model identified 351 At Risk customers who historically purchased frequently but had not purchased recently.

Together, these customers generated approximately £951.7K in historical net revenue.

Examples of high-value At Risk customers included:

| Customer ID | Days Since Purchase | Orders | Net Customer Value |
|---|---:|---:|---:|
| 16754 | 373 | 29 | £56,560.58 |
| 17850 | 373 | 155 | £55,703.13 |
| 13093 | 276 | 55 | £54,073.73 |
| 13902 | 633 | 5 | £30,411.26 |
| 12482 | 577 | 29 | £21,893.53 |

Customer `17850` is particularly notable, having previously completed **155 orders** and generated more than **£55K**, despite having been inactive for more than a year.

These customers represent potential targets for re-engagement campaigns.

---

## 5. Customer Revenue Concentration

Customer revenue is highly concentrated among the retailer's most valuable customers.

| Customer Group | Customers | Net Revenue | Revenue % |
|---|---:|---:|---:|
| Top 1% | 59 | £5.21M | **31.09%** |
| Top 2–5% | 233 | £3.33M | **19.88%** |
| Top 6–20% | 876 | £4.30M | **25.66%** |
| Bottom 80% | 4,669 | £3.91M | **23.37%** |

The results show that:

- The **top 1%** generate **31.09%** of customer-linked net revenue
- The **top 5%** generate **50.97%**
- The **top 20%** generate **76.63%**

This closely resembles a Pareto-style revenue distribution and further demonstrates the importance of high-value customer retention.

---

## 6. Geographic Performance

The retailer is heavily concentrated in its domestic UK market.

The **United Kingdom generates 85.21% of gross revenue**, or approximately **£17.87M**.

### Top International Markets

| Country | Orders | Gross Revenue | Average Order Value |
|---|---:|---:|---:|
| EIRE | 626 | £664,431.78 | £1,061.39 |
| Netherlands | 228 | £554,232.34 | £2,430.84 |
| Germany | 789 | £431,262.46 | £546.59 |
| France | 622 | £356,944.60 | £573.87 |
| Australia | 95 | £169,968.11 | £1,789.14 |

The Netherlands stands out as a particularly valuable international market. Despite having significantly fewer orders than Germany or France, it generated more than **£554K** in revenue and an average order value of approximately £2,431.

Australia, Denmark, Japan, and several other smaller markets also demonstrated relatively high average order values.

---

# Business Recommendations

Based on the analysis, several opportunities emerge:

### 1. Protect High-Value Customers

Champions account for nearly 70% of identified net revenue despite representing only 22% of customers.

Retention programs, loyalty benefits, and proactive customer engagement should prioritize this group.

### 2. Re-Engage Valuable At-Risk Customers

The At Risk segment contains historically valuable customers who have stopped purchasing recently.

Targeted campaigns could prioritize customers with both high historical frequency and monetary value.

### 3. Prepare for Seasonal Demand

Revenue consistently increases during the September–November period.

Inventory, marketing, and operational capacity should be planned ahead of the fourth-quarter sales increase.

### 4. Evaluate High-Value International Markets

Markets such as the Netherlands and Australia generate relatively high average order values.

Further analysis could determine whether targeted international marketing or distribution investments could expand these markets.

### 5. Monitor Product Cancellations Carefully

High cancellation percentages should not automatically be interpreted as widespread product-quality problems.

Several extreme rates were driven by individual bulk transactions, demonstrating the importance of analyzing both cancellation volume and cancellation frequency.

---

# Repository Structure

```text
Ecommerce-SQL-Analytics/
│
├── README.md
│
├── data/
│   └── README.md
│
└── sql/
    ├── 01_data_quality.sql
    ├── 02_sales_analysis.sql
    ├── 03_product_analysis.sql
    ├── 04_customer_analysis.sql
    └── 05_geographic_analysis.sql
```

### SQL Files

**`01_data_quality.sql`**  
Explores missing values, unusual transactions, cancellations, potential duplicates, and creates the `clean_sales` view.

**`02_sales_analysis.sql`**  
Calculates core business KPIs and analyzes monthly, month-over-month, and year-over-year revenue trends.

**`03_product_analysis.sql`**  
Analyzes product revenue, sales volume, canonical product descriptions, net product performance, and cancellations.

**`04_customer_analysis.sql`**  
Analyzes customer value, builds the RFM segmentation model, identifies At Risk customers, and measures revenue concentration.

**`05_geographic_analysis.sql`**  
Analyzes domestic and international revenue performance, order volume, and average order value.

---

# How to Run the Project

1. Install PostgreSQL and a PostgreSQL client such as pgAdmin.
2. Create a PostgreSQL database for the project.
3. Import the source dataset into a table named `raw_transactions`.
4. Run the SQL scripts in numerical order:

```text
01_data_quality.sql
02_sales_analysis.sql
03_product_analysis.sql
04_customer_analysis.sql
05_geographic_analysis.sql
```

`01_data_quality.sql` creates the `clean_sales` view used by later scripts.

`04_customer_analysis.sql` creates the `rfm_customer_segments` view used for customer segmentation analysis.

---

## Project Takeaway

This project demonstrates how PostgreSQL can be used to transform more than one million raw transaction records into actionable business insights.

Rather than treating SQL solely as a data-retrieval tool, the analysis uses SQL for **data-quality assessment, KPI development, time-series analysis, product performance analysis, customer segmentation, anomaly investigation, and strategic business recommendations**.
