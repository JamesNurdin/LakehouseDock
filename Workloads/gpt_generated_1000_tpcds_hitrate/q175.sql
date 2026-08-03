/*
Goal: List up to 100 distinct 2001 purchases (from catalog_sales and web_sales) by customers who have no store returns in the same year, showing each purchase amount, whether it exceeds the maximum net paid amount for 2001, and a simple high/low sales category. Results are ordered by net paid descending.
*/
WITH max_net_paid AS (
    SELECT MAX(cs.cs_net_paid) AS max_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),

catalog_purchases AS (
    SELECT
        c.c_customer_id,
        cs.cs_order_number,
        cs.cs_net_paid,
        CASE WHEN cs.cs_net_paid > (SELECT max_paid FROM max_net_paid) THEN 'AboveMax' ELSE 'BelowMax' END AS comparison,
        CASE WHEN cs.cs_net_paid >= 500 THEN 'High' ELSE 'Low' END AS sales_category,
        d.d_date
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
),

web_purchases AS (
    SELECT
        c.c_customer_id,
        ws.ws_order_number AS cs_order_number,
        ws.ws_net_paid AS cs_net_paid,
        CASE WHEN ws.ws_net_paid > (SELECT max_paid FROM max_net_paid) THEN 'AboveMax' ELSE 'BelowMax' END AS comparison,
        CASE WHEN ws.ws_net_paid >= 500 THEN 'High' ELSE 'Low' END AS sales_category,
        d.d_date
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
),

all_purchases AS (
    SELECT * FROM catalog_purchases
    UNION ALL
    SELECT * FROM web_purchases
),

customers_with_returns AS (
    SELECT DISTINCT c.c_customer_id
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)

SELECT
    ap.c_customer_id,
    ap.cs_order_number,
    ap.cs_net_paid,
    ap.comparison,
    ap.sales_category,
    ap.d_date
FROM all_purchases ap
EXCEPT
SELECT
    ap.c_customer_id,
    ap.cs_order_number,
    ap.cs_net_paid,
    ap.comparison,
    ap.sales_category,
    ap.d_date
FROM all_purchases ap
JOIN customers_with_returns cwr ON ap.c_customer_id = cwr.c_customer_id
ORDER BY cs_net_paid DESC
LIMIT 100
