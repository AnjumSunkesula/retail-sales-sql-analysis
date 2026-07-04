-- ===================================================================
-- Retail Sales SQL Analysis
-- Author: Anjum Sunkesula
-- Description: End-to-end SQL project covering schema design, data
-- cleaning, and business-question queries on a retail sales dataset.
-- Engine: MySQL 8.0+
-- ===================================================================

-- -------------------------------------------------------------------
-- 1. DATABASE & SCHEMA SETUP
-- -------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS retail_sales_db;
USE retail_sales_db;

DROP TABLE IF EXISTS retail_sales;

CREATE TABLE retail_sales (
    transaction_id     INT PRIMARY KEY,
    sale_date          DATE,
    sale_time          TIME,
    customer_id        INT,
    gender              VARCHAR(10),
    age                 INT,
    category            VARCHAR(30),
    quantity            INT,
    price_per_unit      DECIMAL(10,2),
    cogs                DECIMAL(10,2),   -- cost of goods sold
    total_sale          DECIMAL(10,2)
);

-- -------------------------------------------------------------------
-- 2. DATA CLEANING
-- -------------------------------------------------------------------

-- 2.1 Check row count after import
SELECT COUNT(*) AS total_rows FROM retail_sales;

-- 2.2 Find rows with NULLs in any key column
SELECT *
FROM retail_sales
WHERE transaction_id IS NULL
   OR sale_date IS NULL
   OR sale_time IS NULL
   OR customer_id IS NULL
   OR category IS NULL
   OR quantity IS NULL
   OR price_per_unit IS NULL
   OR cogs IS NULL
   OR total_sale IS NULL;

-- 2.3 Remove incomplete rows (run only after reviewing them above)
DELETE FROM retail_sales
WHERE transaction_id IS NULL
   OR sale_date IS NULL
   OR sale_time IS NULL
   OR customer_id IS NULL
   OR category IS NULL
   OR quantity IS NULL
   OR price_per_unit IS NULL
   OR cogs IS NULL
   OR total_sale IS NULL;

-- 2.4 Sanity check: total_sale should equal quantity * price_per_unit
SELECT transaction_id, quantity, price_per_unit, total_sale
FROM retail_sales
WHERE total_sale <> ROUND(quantity * price_per_unit, 2);

-- -------------------------------------------------------------------
-- 3. EXPLORATORY / BUSINESS-QUESTION QUERIES
-- -------------------------------------------------------------------

-- Q1: How many unique customers do we have?
SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM retail_sales;

-- Q2: What product categories do we sell?
SELECT DISTINCT category
FROM retail_sales;

-- Q3: Total revenue and total orders by category
SELECT
    category,
    SUM(total_sale)   AS total_revenue,
    COUNT(*)          AS total_orders
FROM retail_sales
GROUP BY category
ORDER BY total_revenue DESC;

-- Q4: Top 5 customers by total spend
SELECT
    customer_id,
    SUM(total_sale) AS total_spend
FROM retail_sales
GROUP BY customer_id
ORDER BY total_spend DESC
LIMIT 5;

-- Q5: Average sale value by month, to spot seasonal trends
SELECT
    YEAR(sale_date)  AS sale_year,
    MONTH(sale_date) AS sale_month,
    ROUND(AVG(total_sale), 2) AS avg_sale
FROM retail_sales
GROUP BY YEAR(sale_date), MONTH(sale_date)
ORDER BY sale_year, sale_month;

-- Q6: Orders by time of day (morning / afternoon / evening)
SELECT
    CASE
        WHEN HOUR(sale_time) < 12 THEN 'Morning'
        WHEN HOUR(sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift,
    COUNT(*) AS total_orders
FROM retail_sales
GROUP BY shift
ORDER BY total_orders DESC;

-- Q7: Best-selling category by gender
SELECT
    gender,
    category,
    COUNT(*) AS total_orders
FROM retail_sales
GROUP BY gender, category
ORDER BY gender, total_orders DESC;

-- Q8: Customers whose average order value is above the overall average
-- (subquery example)
SELECT
    customer_id,
    ROUND(AVG(total_sale), 2) AS avg_order_value
FROM retail_sales
GROUP BY customer_id
HAVING AVG(total_sale) > (
    SELECT AVG(total_sale) FROM retail_sales
)
ORDER BY avg_order_value DESC;

-- Q9: Monthly running total of revenue (window function)
SELECT
    sale_date,
    total_sale,
    SUM(total_sale) OVER (ORDER BY sale_date) AS running_total
FROM retail_sales
ORDER BY sale_date;

-- Q10: Profit margin by category (using cogs vs total_sale)
SELECT
    category,
    SUM(total_sale) AS revenue,
    SUM(cogs)        AS cost,
    ROUND(SUM(total_sale) - SUM(cogs), 2)                       AS gross_profit,
    ROUND((SUM(total_sale) - SUM(cogs)) / SUM(total_sale) * 100, 2) AS margin_pct
FROM retail_sales
GROUP BY category
ORDER BY margin_pct DESC;
