WITH electronics_sales AS (
   SELECT c.c_customer_id AS customer_id,
          SUM(ws.ws_ext_sales_price) AS sales_amount
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2022
     AND i.i_category = 'Electronics'
   GROUP BY c.c_customer_id
),

furniture_sales AS (
   SELECT c.c_customer_id AS customer_id,
          SUM(ws.ws_ext_sales_price) AS sales_amount
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   WHERE d.d_year = 2022
     AND i.i_category = 'Furniture'
   GROUP BY c.c_customer_id
),

combined AS (
   SELECT customer_id, 'Electronics' AS category, sales_amount
   FROM electronics_sales
   UNION ALL
   SELECT customer_id, 'Furniture' AS category, sales_amount
   FROM furniture_sales
)
SELECT customer_id,
       category,
       sales_amount
FROM combined
WHERE sales_amount > 500
ORDER BY sales_amount DESC
LIMIT 100
