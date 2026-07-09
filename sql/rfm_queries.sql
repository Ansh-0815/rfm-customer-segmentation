-- ============================================================
-- RFM Customer Segmentation — SQL Data Preparation
-- Dataset: Online Retail II (UCI Machine Learning Repository)
-- ============================================================

CREATE DATABASE IF NOT EXISTS rfm_segmentation;
USE rfm_segmentation;

-- ------------------------------------------------------------
-- 1. Create raw transactions table
-- ------------------------------------------------------------
CREATE TABLE retail_transactions (
    Invoice VARCHAR(20),
    StockCode VARCHAR(20),
    Description VARCHAR(255),
    Quantity INT,
    InvoiceDate DATETIME,
    Price DECIMAL(10,2),
    CustomerID INT,
    Country VARCHAR(100)
);

-- ------------------------------------------------------------
-- 2. Load raw CSV data
--    Download "online_retail_II.csv" from:
--    https://archive.ics.uci.edu/dataset/502/online+retail+ii
--    and update the file path below to its location on your machine.
-- ------------------------------------------------------------
SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE '/path/to/online_retail_II.csv'  -- << update this path
INTO TABLE retail_transactions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ------------------------------------------------------------
-- 3. Data quality checks
-- ------------------------------------------------------------
SELECT COUNT(*) AS total_rows FROM retail_transactions;

SELECT COUNT(*) AS missing_customer_ids
FROM retail_transactions
WHERE CustomerID IS NULL;

SELECT COUNT(*) AS cancelled_orders
FROM retail_transactions
WHERE Invoice LIKE 'C%';

SELECT COUNT(*) AS negative_quantity_rows
FROM retail_transactions
WHERE Quantity <= 0;

SELECT COUNT(*) AS invalid_price_rows
FROM retail_transactions
WHERE Price <= 0;

SELECT
    MIN(InvoiceDate) AS start_date,
    MAX(InvoiceDate) AS end_date
FROM retail_transactions;

SELECT COUNT(DISTINCT CustomerID) AS distinct_customers
FROM retail_transactions;

SELECT COUNT(DISTINCT Invoice) AS total_invoices
FROM retail_transactions;

SELECT COUNT(*) AS blank_customer_rows
FROM retail_transactions
WHERE CustomerID = 0;

SELECT
    MIN(CustomerID) AS min_id,
    MAX(CustomerID) AS max_id
FROM retail_transactions;

-- ------------------------------------------------------------
-- 4. Preview of usable rows after applying cleaning rules
-- ------------------------------------------------------------
SELECT COUNT(*) AS usable_rows
FROM retail_transactions
WHERE CustomerID <> 0
  AND Invoice NOT LIKE 'C%'
  AND Quantity > 0
  AND Price > 0;

SELECT COUNT(DISTINCT CustomerID) AS valid_customers
FROM retail_transactions
WHERE CustomerID <> 0;

-- ------------------------------------------------------------
-- 5. Build cleaned transactions table
--    Removes cancelled invoices, invalid quantities/prices,
--    and rows with no CustomerID.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS clean_transactions;

CREATE TABLE clean_transactions AS
SELECT *
FROM retail_transactions
WHERE CustomerID <> 0
  AND Invoice NOT LIKE 'C%'
  AND Quantity > 0
  AND Price > 0;

SELECT COUNT(*) AS clean_row_count FROM clean_transactions;

-- ------------------------------------------------------------
-- 6. Build customer-level RFM table
--    Reference date is one day after the last transaction
--    in the dataset (2011-12-09), so Recency is always >= 1.
-- ------------------------------------------------------------
DROP TABLE IF EXISTS rfm_base;

CREATE TABLE rfm_base AS
SELECT
    CustomerID,
    DATEDIFF('2011-12-10', MAX(DATE(InvoiceDate))) AS Recency,
    COUNT(DISTINCT Invoice) AS Frequency,
    ROUND(SUM(Quantity * Price), 2) AS Monetary
FROM clean_transactions
GROUP BY CustomerID
ORDER BY Monetary DESC;

SELECT COUNT(*) AS rfm_customer_count FROM rfm_base;

-- Sanity check on Recency distribution
SELECT
    MIN(Recency) AS min_recency,
    MAX(Recency) AS max_recency,
    AVG(Recency) AS avg_recency
FROM rfm_base;

-- Top 10 customers by spend
SELECT * FROM rfm_base ORDER BY Monetary DESC LIMIT 10;

-- ------------------------------------------------------------
-- 7. Export rfm_base to CSV for the Python notebook
--    NOTE: secure_file_priv restricts where MySQL can write files.
--    Run `SHOW VARIABLES LIKE 'secure_file_priv';` to find the
--    allowed directory, then move/rename the file into
--    ../data/rfm_base.csv for the notebook to pick up.
--
--    If SELECT ... INTO OUTFILE is not permitted on your setup,
--    export rfm_base via MySQL Workbench:
--    Result Grid -> right-click -> Export Resultset -> CSV.
-- ------------------------------------------------------------
SELECT CustomerID, Recency, Frequency, Monetary
FROM rfm_base
INTO OUTFILE '/path/to/output/rfm_base.csv'  -- << update this path
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
