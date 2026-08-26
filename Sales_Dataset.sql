-- =============================================================================
-- PROJECT 1: RETAIL SALES DATA CLEANING & EXPLORATORY DATA ANALYSIS
-- Author   : Mochammad Amir Hamzah
-- Database : sales_data
-- Tool     : MySQL Workbench / MySQL 8.0+
-- =============================================================================
--
-- PROJECT OBJECTIVES
-- 1. Import raw retail sales data into a staging table.
-- 2. Audit missing, duplicate, invalid, and inconsistent records.
-- 3. Standardize text, dates, and numeric data types.
-- 4. Create a clean analytical dataset.
-- 5. Validate the cleaned dataset.
-- 6. Perform exploratory and business-oriented sales analysis.
--
-- DATA PIPELINE
--
-- CSV
--  ↓
-- sales_raw
--  ↓
-- Data Audit
--  ↓
-- Data Cleaning & Standardization
--  ↓
-- sales_transactions
--  ↓
-- Validation
--  ↓
-- Exploratory Data Analysis
--
-- =============================================================================

-- =============================================================================
-- SECTION 1: RAW / STAGING TABLE
-- =============================================================================
--
-- Purpose:
-- Store imported CSV values without modifying the original source data.
--
-- VARCHAR is intentionally used for raw fields because the CSV may contain
-- inconsistent formatting or invalid values that need to be audited first.
--
-- =============================================================================

CREATE TABLE sales_raw (

    product_id VARCHAR(50),

    sale_date VARCHAR(50),

    sales_rep VARCHAR(100),

    region VARCHAR(50),

    sales_amount VARCHAR(50),

    quantity_sold VARCHAR(50),

    product_category VARCHAR(100),

    unit_cost VARCHAR(50),

    unit_price VARCHAR(50),

    customer_type VARCHAR(50),

    discount VARCHAR(50),

    payment_method VARCHAR(50),

    sales_channel VARCHAR(50),

    region_and_sales_rep VARCHAR(150)

);


-- =============================================================================
-- SECTION 2: DATA IMPORT
-- =============================================================================
--
-- IMPORTANT:
-- Update the file path according to your local MySQL Server configuration.
--
-- For GitHub documentation, do not assume this exact path will exist on
-- another computer.
--
-- =============================================================================

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sales_data.csv'

INTO TABLE sales_raw

FIELDS TERMINATED BY ','
ENCLOSED BY '"'

LINES TERMINATED BY '\n'

IGNORE 1 ROWS;


-- =============================================================================
-- SECTION 3: INITIAL DATA AUDIT
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 3.1 Preview raw data
-- -----------------------------------------------------------------------------

SELECT *
FROM sales_raw
LIMIT 10;


-- -----------------------------------------------------------------------------
-- 3.2 Record count
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS total_raw_records
FROM sales_raw;


-- -----------------------------------------------------------------------------
-- 3.3 Missing and empty values
-- -----------------------------------------------------------------------------

SELECT

    COUNT(*) AS total_records,

    SUM(
        product_id IS NULL
        OR TRIM(product_id) = ''
    ) AS missing_product_id,

    SUM(
        sale_date IS NULL
        OR TRIM(sale_date) = ''
    ) AS missing_sale_date,

    SUM(
        sales_rep IS NULL
        OR TRIM(sales_rep) = ''
    ) AS missing_sales_rep,

    SUM(
        region IS NULL
        OR TRIM(region) = ''
    ) AS missing_region,

    SUM(
        sales_amount IS NULL
        OR TRIM(sales_amount) = ''
    ) AS missing_sales_amount,

    SUM(
        quantity_sold IS NULL
        OR TRIM(quantity_sold) = ''
    ) AS missing_quantity,

    SUM(
        product_category IS NULL
        OR TRIM(product_category) = ''
    ) AS missing_product_category,

    SUM(
        unit_cost IS NULL
        OR TRIM(unit_cost) = ''
    ) AS missing_unit_cost,

    SUM(
        unit_price IS NULL
        OR TRIM(unit_price) = ''
    ) AS missing_unit_price,

    SUM(
        customer_type IS NULL
        OR TRIM(customer_type) = ''
    ) AS missing_customer_type,

    SUM(
        discount IS NULL
        OR TRIM(discount) = ''
    ) AS missing_discount,

    SUM(
        payment_method IS NULL
        OR TRIM(payment_method) = ''
    ) AS missing_payment_method,

    SUM(
        sales_channel IS NULL
        OR TRIM(sales_channel) = ''
    ) AS missing_sales_channel

FROM sales_raw;


-- -----------------------------------------------------------------------------
-- 3.4 Duplicate records
-- -----------------------------------------------------------------------------

SELECT

    product_id,
    sale_date,
    sales_rep,
    region,
    sales_amount,
    quantity_sold,
    product_category,
    unit_cost,
    unit_price,
    customer_type,
    discount,
    payment_method,
    sales_channel,

    COUNT(*) AS duplicate_count

FROM sales_raw

GROUP BY

    product_id,
    sale_date,
    sales_rep,
    region,
    sales_amount,
    quantity_sold,
    product_category,
    unit_cost,
    unit_price,
    customer_type,
    discount,
    payment_method,
    sales_channel

HAVING COUNT(*) > 1

ORDER BY duplicate_count DESC;


-- -----------------------------------------------------------------------------
-- 3.5 Duplicate summary
-- -----------------------------------------------------------------------------

WITH duplicate_groups AS (

    SELECT

        product_id,
        sale_date,
        sales_rep,
        region,
        sales_amount,
        quantity_sold,
        product_category,
        unit_cost,
        unit_price,
        customer_type,
        discount,
        payment_method,
        sales_channel,

        COUNT(*) AS row_count

    FROM sales_raw

    GROUP BY

        product_id,
        sale_date,
        sales_rep,
        region,
        sales_amount,
        quantity_sold,
        product_category,
        unit_cost,
        unit_price,
        customer_type,
        discount,
        payment_method,
        sales_channel

)

SELECT

    COUNT(*) AS duplicate_groups,

    SUM(row_count - 1) AS duplicate_rows

FROM duplicate_groups

WHERE row_count > 1;


-- -----------------------------------------------------------------------------
-- 3.6 Invalid sales amounts
-- -----------------------------------------------------------------------------

SELECT *
FROM sales_raw
WHERE CAST(
    NULLIF(TRIM(sales_amount), '')
    AS DECIMAL(12,2)
) < 0;


-- -----------------------------------------------------------------------------
-- 3.7 Invalid quantities
-- -----------------------------------------------------------------------------

SELECT *
FROM sales_raw
WHERE CAST(
    NULLIF(TRIM(quantity_sold), '')
    AS SIGNED
) <= 0;


-- -----------------------------------------------------------------------------
-- 3.8 Invalid unit prices
-- -----------------------------------------------------------------------------

SELECT *
FROM sales_raw
WHERE CAST(
    NULLIF(TRIM(unit_price), '')
    AS DECIMAL(12,2)
) <= 0;


-- -----------------------------------------------------------------------------
-- 3.9 Invalid unit costs
-- -----------------------------------------------------------------------------

SELECT *
FROM sales_raw
WHERE CAST(
    NULLIF(TRIM(unit_cost), '')
    AS DECIMAL(12,2)
) < 0;


-- -----------------------------------------------------------------------------
-- 3.10 Invalid discount values
-- -----------------------------------------------------------------------------

SELECT *
FROM sales_raw
WHERE CAST(
    NULLIF(TRIM(discount), '')
    AS DECIMAL(5,4)
) < 0

OR CAST(
    NULLIF(TRIM(discount), '')
    AS DECIMAL(5,4)
) > 1;


-- -----------------------------------------------------------------------------
-- 3.11 Invalid dates
-- -----------------------------------------------------------------------------

SELECT
    sale_date

FROM sales_raw

WHERE STR_TO_DATE(
    NULLIF(TRIM(sale_date), ''),
    '%Y-%m-%d'
) IS NULL;


-- -----------------------------------------------------------------------------
-- 3.12 Future transaction dates
-- -----------------------------------------------------------------------------

SELECT
    sale_date

FROM sales_raw

WHERE STR_TO_DATE(
    NULLIF(TRIM(sale_date), ''),
    '%Y-%m-%d'
) > CURRENT_DATE();


-- -----------------------------------------------------------------------------
-- 3.13 Whitespace inconsistencies
-- -----------------------------------------------------------------------------

SELECT DISTINCT region
FROM sales_raw
WHERE region <> TRIM(region);


SELECT DISTINCT product_category
FROM sales_raw
WHERE product_category <> TRIM(product_category);


SELECT DISTINCT customer_type
FROM sales_raw
WHERE customer_type <> TRIM(customer_type);


SELECT DISTINCT payment_method
FROM sales_raw
WHERE payment_method <> TRIM(payment_method);


SELECT DISTINCT sales_channel
FROM sales_raw
WHERE sales_channel <> TRIM(sales_channel);


-- =============================================================================
-- SECTION 4: CREATE CLEAN ANALYTICAL TABLE
-- =============================================================================


CREATE TABLE sales_transactions (

    sales_transaction_key INT NOT NULL AUTO_INCREMENT,

    product_id VARCHAR(50),

    sale_date DATE,

    sales_rep VARCHAR(100),

    region VARCHAR(50),

    sales_amount DECIMAL(12,2),

    quantity_sold INT,

    product_category VARCHAR(100),

    unit_cost DECIMAL(12,2),

    unit_price DECIMAL(12,2),

    customer_type VARCHAR(50),

    discount DECIMAL(5,4),

    payment_method VARCHAR(50),

    sales_channel VARCHAR(50),

    PRIMARY KEY (sales_transaction_key)

);


-- =============================================================================
-- SECTION 5: CLEANING & STANDARDIZATION
-- =============================================================================
--
-- The following transformation:
-- - trims whitespace
-- - converts empty strings to NULL
-- - converts dates to DATE
-- - converts numeric fields to appropriate numeric types
-- - standardizes categorical values
--
-- Exact duplicate records are removed using SELECT DISTINCT.
--
-- =============================================================================


INSERT INTO sales_transactions (

    product_id,
    sale_date,
    sales_rep,
    region,
    sales_amount,
    quantity_sold,
    product_category,
    unit_cost,
    unit_price,
    customer_type,
    discount,
    payment_method,
    sales_channel

)

SELECT DISTINCT

    NULLIF(TRIM(product_id), ''),

    STR_TO_DATE(
        NULLIF(TRIM(sale_date), ''),
        '%Y-%m-%d'
    ),

    NULLIF(TRIM(sales_rep), ''),

    CASE
        WHEN LOWER(TRIM(region)) = 'north'
            THEN 'North'

        WHEN LOWER(TRIM(region)) = 'south'
            THEN 'South'

        WHEN LOWER(TRIM(region)) = 'east'
            THEN 'East'

        WHEN LOWER(TRIM(region)) = 'west'
            THEN 'West'

        ELSE NULLIF(TRIM(region), '')
    END,

    CAST(
        NULLIF(TRIM(sales_amount), '')
        AS DECIMAL(12,2)
    ),

    CAST(
        NULLIF(TRIM(quantity_sold), '')
        AS SIGNED
    ),

    CASE

        WHEN LOWER(TRIM(product_category)) = 'electronics'
            THEN 'Electronics'

        WHEN LOWER(TRIM(product_category)) = 'fashion'
            THEN 'Fashion'

        WHEN LOWER(TRIM(product_category)) = 'home'
            THEN 'Home'

        ELSE NULLIF(TRIM(product_category), '')

    END,

    CAST(
        NULLIF(TRIM(unit_cost), '')
        AS DECIMAL(12,2)
    ),

    CAST(
        NULLIF(TRIM(unit_price), '')
        AS DECIMAL(12,2)
    ),

    CASE

        WHEN LOWER(TRIM(customer_type)) = 'new'
            THEN 'New'

        WHEN LOWER(TRIM(customer_type)) = 'returning'
            THEN 'Returning'

        ELSE NULLIF(TRIM(customer_type), '')

    END,

    CAST(
        NULLIF(TRIM(discount), '')
        AS DECIMAL(5,4)
    ),

    CASE

        WHEN LOWER(TRIM(payment_method)) = 'cash'
            THEN 'Cash'

        WHEN LOWER(TRIM(payment_method)) = 'credit card'
            THEN 'Credit Card'

        WHEN LOWER(TRIM(payment_method)) = 'debit card'
            THEN 'Debit Card'

        WHEN LOWER(TRIM(payment_method)) = 'paypal'
            THEN 'PayPal'

        ELSE NULLIF(TRIM(payment_method), '')

    END,

    CASE

        WHEN LOWER(TRIM(sales_channel)) = 'online'
            THEN 'Online'

        WHEN LOWER(TRIM(sales_channel)) = 'offline'
            THEN 'Offline'

        WHEN LOWER(TRIM(sales_channel)) = 'store'
            THEN 'Store'

        ELSE NULLIF(TRIM(sales_channel), '')

    END

FROM sales_raw;


-- =============================================================================
-- SECTION 6: REMOVE INVALID TRANSACTIONS
-- =============================================================================
--
-- Records that cannot be reliably used for sales analysis are removed.
--
-- =============================================================================


DELETE FROM sales_transactions

WHERE sale_date IS NULL
   OR sale_date > CURRENT_DATE()

   OR quantity_sold IS NULL
   OR quantity_sold <= 0

   OR unit_cost IS NULL
   OR unit_cost < 0

   OR unit_price IS NULL
   OR unit_price <= 0

   OR sales_amount IS NULL
   OR sales_amount < 0

   OR discount IS NULL
   OR discount < 0
   OR discount > 1;


-- =============================================================================
-- SECTION 7: SALES AMOUNT CONSISTENCY CHECK
-- =============================================================================
--
-- Expected sales amount:
--
-- Quantity × Unit Price × (1 - Discount)
--
-- A tolerance of 0.01 is used because sales amounts are stored to two
-- decimal places.
--
-- This query identifies records where the reported sales amount differs
-- materially from the calculated amount.
--
-- =============================================================================

SELECT

    sales_transaction_key,

    product_id,

    quantity_sold,

    unit_price,

    discount,

    sales_amount,

    ROUND(
        quantity_sold
        * unit_price
        * (1 - discount),
        2
    ) AS calculated_sales_amount

FROM sales_transactions

WHERE ABS(

    sales_amount
    -
    ROUND(
        quantity_sold
        * unit_price
        * (1 - discount),
        2
    )

) > 0.01;


-- =============================================================================
-- SECTION 8: POST-CLEANING VALIDATION
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 8.1 Final record count
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*) AS total_clean_records
FROM sales_transactions;


-- -----------------------------------------------------------------------------
-- 8.2 Remaining NULL values
-- -----------------------------------------------------------------------------

SELECT

    COUNT(*) AS total_records,

    SUM(product_id IS NULL) AS null_product_id,
    SUM(sale_date IS NULL) AS null_sale_date,
    SUM(sales_rep IS NULL) AS null_sales_rep,
    SUM(region IS NULL) AS null_region,
    SUM(sales_amount IS NULL) AS null_sales_amount,
    SUM(quantity_sold IS NULL) AS null_quantity,
    SUM(product_category IS NULL) AS null_product_category,
    SUM(unit_cost IS NULL) AS null_unit_cost,
    SUM(unit_price IS NULL) AS null_unit_price,
    SUM(customer_type IS NULL) AS null_customer_type,
    SUM(discount IS NULL) AS null_discount,
    SUM(payment_method IS NULL) AS null_payment_method,
    SUM(sales_channel IS NULL) AS null_sales_channel

FROM sales_transactions;


-- -----------------------------------------------------------------------------
-- 8.3 Final numeric validation
-- -----------------------------------------------------------------------------

SELECT *

FROM sales_transactions

WHERE sales_amount < 0
   OR quantity_sold <= 0
   OR unit_cost < 0
   OR unit_price <= 0
   OR discount < 0
   OR discount > 1;


-- -----------------------------------------------------------------------------
-- 8.4 Final date validation
-- -----------------------------------------------------------------------------

SELECT

    MIN(sale_date) AS earliest_sale_date,

    MAX(sale_date) AS latest_sale_date

FROM sales_transactions;


-- -----------------------------------------------------------------------------
-- 8.5 Final category validation
-- -----------------------------------------------------------------------------

SELECT DISTINCT product_category
FROM sales_transactions
ORDER BY product_category;


SELECT DISTINCT customer_type
FROM sales_transactions
ORDER BY customer_type;


SELECT DISTINCT region
FROM sales_transactions
ORDER BY region;


SELECT DISTINCT payment_method
FROM sales_transactions
ORDER BY payment_method;


SELECT DISTINCT sales_channel
FROM sales_transactions
ORDER BY sales_channel;


-- =============================================================================
-- SECTION 9: EXPLORATORY DATA ANALYSIS
-- =============================================================================


-- -----------------------------------------------------------------------------
-- QUERY 1: OVERALL SALES PERFORMANCE
-- -----------------------------------------------------------------------------

SELECT

    COUNT(*) AS total_transactions,

    SUM(quantity_sold) AS total_units_sold,

    ROUND(
        SUM(sales_amount),
        2
    ) AS total_revenue,

    ROUND(
        AVG(sales_amount),
        2
    ) AS average_transaction_value

FROM sales_transactions;


-- -----------------------------------------------------------------------------
-- QUERY 2: REVENUE BY PRODUCT CATEGORY
-- -----------------------------------------------------------------------------

SELECT

    product_category,

    COUNT(*) AS transaction_count,

    SUM(quantity_sold) AS units_sold,

    ROUND(
        SUM(sales_amount),
        2
    ) AS total_revenue

FROM sales_transactions

GROUP BY product_category

ORDER BY total_revenue DESC;


-- -----------------------------------------------------------------------------
-- QUERY 3: CATEGORY REVENUE CONTRIBUTION
-- -----------------------------------------------------------------------------

WITH category_revenue AS (

    SELECT

        product_category,

        SUM(sales_amount) AS revenue

    FROM sales_transactions

    GROUP BY product_category

)

SELECT

    product_category,

    ROUND(revenue, 2) AS total_revenue,

    ROUND(

        revenue
        / NULLIF(SUM(revenue) OVER (), 0)
        * 100,

        2

    ) AS revenue_share_percentage

FROM category_revenue

ORDER BY revenue DESC;


-- -----------------------------------------------------------------------------
-- QUERY 4: REVENUE BY REGION
-- -----------------------------------------------------------------------------

SELECT

    region,

    COUNT(*) AS transaction_count,

    SUM(quantity_sold) AS units_sold,

    ROUND(
        SUM(sales_amount),
        2
    ) AS total_revenue

FROM sales_transactions

GROUP BY region

ORDER BY total_revenue DESC;


-- -----------------------------------------------------------------------------
-- QUERY 5: REVENUE BY CUSTOMER TYPE
-- -----------------------------------------------------------------------------

SELECT

    customer_type,

    COUNT(*) AS transaction_count,

    ROUND(
        SUM(sales_amount),
        2
    ) AS total_revenue,

    ROUND(
        AVG(sales_amount),
        2
    ) AS average_transaction_value

FROM sales_transactions

GROUP BY customer_type

ORDER BY total_revenue DESC;


-- -----------------------------------------------------------------------------
-- QUERY 6: REVENUE BY SALES CHANNEL
-- -----------------------------------------------------------------------------

SELECT

    sales_channel,

    COUNT(*) AS transaction_count,

    ROUND(
        SUM(sales_amount),
        2
    ) AS total_revenue,

    ROUND(
        AVG(sales_amount),
        2
    ) AS average_transaction_value

FROM sales_transactions

GROUP BY sales_channel

ORDER BY total_revenue DESC;


-- -----------------------------------------------------------------------------
-- QUERY 7: REVENUE BY PAYMENT METHOD
-- -----------------------------------------------------------------------------

SELECT

    payment_method,

    COUNT(*) AS transaction_count,

    ROUND(
        SUM(sales_amount),
        2
    ) AS total_revenue

FROM sales_transactions

GROUP BY payment_method

ORDER BY total_revenue DESC;


-- =============================================================================
-- SECTION 10: TIME-BASED ANALYSIS
-- =============================================================================


-- -----------------------------------------------------------------------------
-- QUERY 8: MONTHLY REVENUE TREND
-- -----------------------------------------------------------------------------

SELECT

    YEAR(sale_date) AS sales_year,

    MONTH(sale_date) AS sales_month,

    ROUND(
        SUM(sales_amount),
        2
    ) AS monthly_revenue

FROM sales_transactions

GROUP BY

    YEAR(sale_date),
    MONTH(sale_date)

ORDER BY

    sales_year,
    sales_month;


-- -----------------------------------------------------------------------------
-- QUERY 9: MONTH-OVER-MONTH REVENUE GROWTH
-- -----------------------------------------------------------------------------

WITH monthly_revenue AS (

    SELECT

        YEAR(sale_date) AS sales_year,

        MONTH(sale_date) AS sales_month,

        SUM(sales_amount) AS monthly_revenue

    FROM sales_transactions

    GROUP BY

        YEAR(sale_date),
        MONTH(sale_date)

),

monthly_growth AS (

    SELECT

        sales_year,

        sales_month,

        monthly_revenue,

        LAG(monthly_revenue) OVER (

            ORDER BY
                sales_year,
                sales_month

        ) AS previous_month_revenue

    FROM monthly_revenue

)

SELECT

    sales_year,

    sales_month,

    ROUND(
        monthly_revenue,
        2
    ) AS current_month_revenue,

    ROUND(
        previous_month_revenue,
        2
    ) AS previous_month_revenue,

    ROUND(

        (
            monthly_revenue
            - previous_month_revenue
        ),

        2

    ) AS absolute_growth,

    ROUND(

        (
            (
                monthly_revenue
                - previous_month_revenue
            )
            / NULLIF(previous_month_revenue, 0)
        )
        * 100,

        2

    ) AS mom_growth_percentage

FROM monthly_growth

ORDER BY

    sales_year,
    sales_month;


-- =============================================================================
-- SECTION 11: DISCOUNT ANALYSIS
-- =============================================================================


-- -----------------------------------------------------------------------------
-- QUERY 10: REVENUE BY DISCOUNT RANGE
-- -----------------------------------------------------------------------------

SELECT

    CASE

        WHEN discount = 0
            THEN 'No Discount'

        WHEN discount <= 0.10
            THEN '1-10%'

        WHEN discount <= 0.20
            THEN '11-20%'

        WHEN discount <= 0.30
            THEN '21-30%'

        ELSE 'Above 30%'

    END AS discount_range,

    COUNT(*) AS transaction_count,

    ROUND(
        SUM(sales_amount),
        2
    ) AS total_revenue,

    ROUND(
        AVG(sales_amount),
        2
    ) AS average_transaction_value

FROM sales_transactions

GROUP BY

    CASE

        WHEN discount = 0
            THEN 'No Discount'

        WHEN discount <= 0.10
            THEN '1-10%'

        WHEN discount <= 0.20
            THEN '11-20%'

        WHEN discount <= 0.30
            THEN '21-30%'

        ELSE 'Above 30%'

    END

ORDER BY total_revenue DESC;


-- =============================================================================
-- SECTION 12: SALES REPRESENTATIVE PERFORMANCE
-- =============================================================================


SELECT

    sales_rep,

    COUNT(*) AS transaction_count,

    SUM(quantity_sold) AS total_units_sold,

    ROUND(
        SUM(sales_amount),
        2
    ) AS total_revenue,

    ROUND(
        AVG(sales_amount),
        2
    ) AS average_transaction_value

FROM sales_transactions

GROUP BY sales_rep

ORDER BY total_revenue DESC;


-- =============================================================================
-- SECTION 13: PROFITABILITY ANALYSIS
-- =============================================================================
--
-- Estimated gross profit:
--
-- (Unit Price - Unit Cost) × Quantity
--
-- Note:
-- This is an estimated gross profit based on unit price and unit cost.
-- If sales_amount includes discounts, actual realized profit may differ.
--
-- =============================================================================


-- -----------------------------------------------------------------------------
-- QUERY 11: ESTIMATED GROSS PROFIT BY CATEGORY
-- -----------------------------------------------------------------------------

SELECT

    product_category,

    ROUND(

        SUM(
            (unit_price - unit_cost)
            * quantity_sold
        ),

        2

    ) AS estimated_gross_profit,

    ROUND(
        SUM(sales_amount),
        2
    ) AS total_revenue

FROM sales_transactions

GROUP BY product_category

ORDER BY estimated_gross_profit DESC;


-- -----------------------------------------------------------------------------
-- QUERY 12: ESTIMATED PROFIT MARGIN BY CATEGORY
-- -----------------------------------------------------------------------------

SELECT

    product_category,

    ROUND(
        SUM(sales_amount),
        2
    ) AS total_revenue,

    ROUND(

        SUM(
            (unit_price - unit_cost)
            * quantity_sold
        ),

        2

    ) AS estimated_gross_profit,

    ROUND(

        SUM(
            (unit_price - unit_cost)
            * quantity_sold
        )
        / NULLIF(SUM(sales_amount), 0)
        * 100,

        2

    ) AS estimated_gross_margin_percentage

FROM sales_transactions

GROUP BY product_category

ORDER BY estimated_gross_margin_percentage DESC;


-- =============================================================================
-- SECTION 14: FINAL DATASET REVIEW
-- =============================================================================


SELECT *
FROM sales_transactions
LIMIT 20;


DESCRIBE sales_transactions;


SELECT
    COUNT(*) AS final_record_count
FROM sales_transactions;


-- =============================================================================
-- END OF PROJECT 1
-- =============================================================================