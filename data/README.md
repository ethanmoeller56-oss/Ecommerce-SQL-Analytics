# Dataset

## Overview

This project uses a transactional e-commerce dataset containing more than 1 million records from a UK-based online retailer.

The dataset covers transactions from December 2009 through December 2011 and includes purchases and cancellations from customers across multiple countries.

## Dataset

The dataset used for this project is publicly available from

Online Retail II https://archive.ics.uci.edu/dataset/502/online%2Bretail%2Bii?utm_source=chatgpt.com

The raw dataset contains more than 1 million transaction records from a UK-based online retailer covering December 2009 through December 2011.

The full raw CSV is not included in this repository because of its size. The SQL scripts assume the source data has been imported into PostgreSQL as a table named `raw_transactions`.

## Dataset Fields

| Column | Description |
|---|---|
| Invoice | Unique invoice identifier. Cancellation invoices begin with "C". |
| StockCode | Product identifier |
| Description | Product description |
| Quantity | Number of units associated with the transaction |
| InvoiceDate | Date and time of the transaction |
| Price | Unit price in British pounds (GBP) |
| Customer ID | Customer identifier |
| Country | Customer country |

## Data Quality Considerations

Several data-quality issues were identified during exploratory analysis, including:

- Missing customer IDs
- Zero-price transactions
- Negative quantities associated with cancellations and inventory adjustments
- Negative prices associated with accounting adjustments
- Inconsistent product descriptions for the same stock code
- Potential duplicate transaction rows
- Extreme transaction and cancellation quantities

A total of 34,335 excess exact-match rows were identified as potential duplicates. Removing all apparent duplicates would reduce gross revenue by approximately £496,334, or 2.37%.

Because the source data does not contain a unique transaction-line identifier, identical rows cannot reliably be classified as erroneous duplicates rather than legitimate repeated line items. These records were therefore retained in the primary analysis.

## Analytical Sales View

A PostgreSQL view named `clean_sales` was created for gross sales analysis.

The view retains transactions where:

- Quantity is greater than zero
- Price is greater than zero
- The invoice is not identified as a cancellation

Cancellation records are incorporated separately where net revenue or cancellation behavior is analyzed.

## Currency

All monetary values in this project are reported in British pounds (GBP).

## Raw Data

The full raw CSV is not included in this repository because of its size. The SQL scripts assume the source data has been imported into PostgreSQL as a table named `raw_transactions`.
