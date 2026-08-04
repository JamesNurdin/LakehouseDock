WITH union_data AS (
   SELECT
       ws.ws_order_number,
       ws.ws_item_sk,
       ws.ws_ext_sales_price,
       wr.wr_refunded_cash,
       d.d_year,
       c.c_customer_sk,
       c.c_birth_month
   FROM web_sales ws TABLESAMPLE BERNOULLI (10)
   FULL OUTER JOIN web_returns wr
       ON ws.ws_order_number = wr.wr_order_number
   JOIN date_dim d
       ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN customer c
       ON ws.ws_bill_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2001
     AND c.c_birth_month = 5
     AND ws.ws_ext_discount_amt > 500
     AND wr.wr_refunded_cash < 200

   UNION DISTINCT

   SELECT
       ws.ws_order_number,
       ws.ws_item_sk,
       ws.ws_ext_sales_price,
       wr.wr_refunded_cash,
       d.d_year,
       c.c_customer_sk,
       c.c_birth_month
   FROM web_sales ws TABLESAMPLE BERNOULLI (10)
   FULL OUTER JOIN web_returns wr
       ON ws.ws_order_number = wr.wr_order_number
   JOIN date_dim d
       ON ws.ws_ship_date_sk = d.d_date_sk
   JOIN customer c
       ON ws.ws_ship_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2002
     AND c.c_birth_month = 12
     AND ws.ws_ext_discount_amt BETWEEN 1000 AND 1500
     AND wr.wr_refunded_cash IS NOT NULL
)
SELECT
   d_year,
   COUNT(DISTINCT ws_item_sk) AS distinct_items_sold,
   COUNT(DISTINCT c_customer_sk) AS distinct_customers,
   SUM(ws_ext_sales_price) AS total_sales,
   AVG(ws_ext_sales_price) AS avg_sales,
   MIN(ws_ext_sales_price) AS min_sales,
   MAX(ws_ext_sales_price) AS max_sales
FROM union_data
GROUP BY d_year
ORDER BY total_sales DESC
LIMIT 100
