WITH returns AS (
   SELECT c.c_customer_id AS customer_id,
          d.d_year AS year,
          sr.sr_return_amt_inc_tax AS amount
   FROM store_returns sr
   FULL OUTER JOIN customer c
       ON sr.sr_customer_sk = c.c_customer_sk
   JOIN date_dim d
       ON sr.sr_returned_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND sr.sr_return_amt_inc_tax > 50
),
sales AS (
   SELECT c.c_customer_id AS customer_id,
          d.d_year AS year,
          cs.cs_ext_sales_price AS amount
   FROM catalog_sales cs
   FULL OUTER JOIN customer c
       ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN date_dim d
       ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND cs.cs_ext_sales_price > 100
),
intersected AS (
   SELECT customer_id, year, amount FROM returns
   INTERSECT
   SELECT customer_id, year, amount FROM sales
)
SELECT
   ROW_NUMBER() OVER (ORDER BY amount DESC) AS row_num,
   customer_id,
   year,
   amount
FROM intersected
ORDER BY row_num
OFFSET 0
LIMIT 100
