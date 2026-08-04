/* Goal: Identify customers who both purchased and returned items in 2001, exclude customers whose first sales were before 2000, add customers who bought items using a catalog promotion in 2001, and show each customer's total sales amount. */
WITH sales_cust AS (
    SELECT DISTINCT ss.ss_customer_sk AS customer_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
return_cust AS (
    SELECT DISTINCT wr.wr_returning_customer_sk AS customer_sk
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
intersect_cust AS (
    SELECT customer_sk FROM sales_cust
    INTERSECT
    SELECT customer_sk FROM return_cust
),
promo_cust AS (
    SELECT DISTINCT ss.ss_customer_sk AS customer_sk
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d ON p.p_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND p.p_channel_catalog = 'N'
),
filtered_intersect AS (
    SELECT ic.customer_sk
    FROM intersect_cust ic
    WHERE ic.customer_sk NOT IN (
        SELECT c.c_customer_sk
        FROM customer c
        JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
        WHERE d.d_year < 2000
    )
)
SELECT f.customer_sk,
       (SELECT SUM(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = f.customer_sk) AS total_sales
FROM filtered_intersect f

UNION

SELECT pc.customer_sk,
       (SELECT SUM(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = pc.customer_sk) AS total_sales
FROM promo_cust pc

ORDER BY customer_sk
LIMIT 100
