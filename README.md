# Customer Segmentation using RFM Analysis

SQL + Python project that segments retail customers using **Recency, Frequency, and Monetary (RFM)** analysis, in order to support targeted marketing, retention, and revenue growth decisions.

## Executive Summary

- Segmented **5,878 customers** from the Online Retail II dataset using RFM analysis.
- Identified **Champions** and **Loyal Customers** as the highest-revenue segments, despite being a smaller share of the customer base.
- Flagged a meaningful **At Risk / Lost Customers** group for win-back campaigns.
- Recommended segment-specific marketing actions to improve retention and revenue without increasing overall marketing spend.

## Business Problem

Many companies spend significant marketing budgets treating every customer the same. However, customers have very different purchasing behaviors and lifetime values. RFM analysis groups customers into meaningful business segments — such as Champions, Loyal Customers, At Risk, and Lost Customers — so that businesses can:

- Improve customer retention
- Reduce customer churn
- Optimize marketing campaigns
- Increase customer lifetime value
- Allocate marketing budgets more efficiently

## Dataset

**Source:** [Online Retail II Dataset](https://archive.ics.uci.edu/dataset/502/online+retail+ii) (UCI Machine Learning Repository)

Historical transactions from a UK-based online retailer, covering **December 2009 – December 2011**.

The raw dataset is not included in this repo (~45 MB). Download `online_retail_II.csv` from the link above if you want to re-run the SQL pipeline from scratch. The cleaned, customer-level output of that pipeline (`data/rfm_base.csv`) **is** included, so the notebook can be run immediately without MySQL.

## Project Structure

```
rfm-customer-segmentation/
├── README.md
├── requirements.txt
├── LICENSE
├── .gitignore
├── sql/
│   └── rfm_queries.sql        # Data cleaning + RFM table build (MySQL)
├── notebook/
│   └── rfm_analysis.ipynb     # Segmentation, EDA, visualizations, insights
└── data/
    └── rfm_base.csv           # Customer-level RFM table (output of SQL step)
```

## Methodology

### 1. Data Cleaning (SQL — `sql/rfm_queries.sql`)

Raw transactions are loaded into MySQL and cleaned by removing:

- Cancelled invoices (`Invoice` starting with `C`)
- Rows with missing/zero `CustomerID`
- Non-positive quantities
- Non-positive prices

### 2. RFM Table Build (SQL)

For each customer, the cleaned transactions are aggregated into:

| Metric | Definition |
|---|---|
| **Recency** | Days since the customer's last purchase (relative to 2011-12-10, one day after the last transaction in the dataset) |
| **Frequency** | Number of distinct invoices (orders) |
| **Monetary** | Total amount spent (`Quantity * Price`) |

The result is exported to `data/rfm_base.csv` and used as the input to the Python analysis.

### 3. Scoring & Segmentation (Python — `notebook/rfm_analysis.ipynb`)

- Each customer is scored 1–4 on Recency, Frequency, and Monetary using quartiles (`pd.qcut`).
- Scores are combined into an RFM score and mapped to business segments (Champions, Loyal Customers, Big Spenders, Potential Loyalists, At Risk, Lost Customers, Others) using rule-based logic.
- Segment-level summary statistics and 8 visualizations (distribution, revenue, frequency, recency, correlation, etc.) are used to validate the segmentation and derive business recommendations.

## How to Reproduce

### Option A — Just run the notebook (fastest)

The cleaned `data/rfm_base.csv` is already included, so you can skip the SQL step entirely.

```bash
git clone <this-repo-url>
cd rfm-customer-segmentation
pip install -r requirements.txt
jupyter notebook notebook/rfm_analysis.ipynb
```

### Option B — Rebuild from raw data

1. Download `online_retail_II.csv` from the [UCI dataset page](https://archive.ics.uci.edu/dataset/502/online+retail+ii) and note its path.
2. Open `sql/rfm_queries.sql`, update the `LOAD DATA LOCAL INFILE` path (and the `INTO OUTFILE` path for the export step) to match your machine.
3. Run the script in MySQL / MySQL Workbench. This creates `clean_transactions` and `rfm_base` tables and exports `rfm_base` to CSV.
4. Replace `data/rfm_base.csv` with your newly exported file (or point the notebook at it).
5. Run the notebook as in Option A.

> **Note:** `LOAD DATA LOCAL INFILE` and `SELECT ... INTO OUTFILE` require `local_infile` enabled and, for the export, permissions tied to MySQL's `secure_file_priv` setting. If `INTO OUTFILE` isn't permitted on your setup, export the `rfm_base` table via MySQL Workbench's **Export Resultset → CSV** instead.

## Key Findings

- Customer value is highly concentrated: a relatively small **Champions** segment drives a disproportionate share of total revenue.
- A large number of customers fall into **At Risk** or **Lost** categories, representing a significant, currently-unaddressed churn risk.
- **Frequency and Monetary** are positively correlated — customers who order more often also tend to spend more per relationship, reinforcing the value of loyalty-driven retention strategies.

## Business Recommendations

- Reward **Champions** through exclusive loyalty programs.
- Retain **Loyal Customers** with personalized offers and membership benefits.
- Convert **Potential Loyalists** into repeat customers through targeted promotions.
- Increase repeat purchase rate among **Big Spenders** using premium services.
- Re-engage **At Risk** customers with personalized email campaigns and limited-time discounts.
- Test win-back campaigns for **Lost Customers** before committing significant budget.

## Limitations

- Customer demographics were unavailable.
- Product categories were not analyzed.
- Seasonal purchasing behavior was not considered.
- Marketing campaign history was unavailable.
- Customer Lifetime Value (CLV) was not modeled.
- Segmentation is rule-based rather than machine-learning driven.

## Future Improvements

- Customer Lifetime Value (CLV) prediction
- Churn prediction model
- K-Means clustering as an alternative to rule-based segmentation
- Product recommendation system
- Cohort analysis
- Marketing campaign effectiveness analysis
- Interactive Power BI / Tableau dashboard

## Tech Stack

- **SQL:** MySQL (data cleaning, aggregation)
- **Python:** pandas, matplotlib, seaborn (analysis & visualization)
- **Environment:** Jupyter Notebook

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
