WITH web_sales_agg AS (
   SELECT c.c_customer_id AS customer_id,
          sum(ws.ws_ext_sales_price) AS total_sales
   FROM web_sales ws
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450994
   GROUP BY c.c_customer_id
),
store_returns_agg AS (
   SELECT c.c_customer_id AS customer_id,
          sum(sr.sr_return_amt) AS total_sales
   FROM store_returns sr
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   WHERE sr.sr_returned_date_sk BETWEEN 2450815 AND 2450994
   GROUP BY c.c_customer_id
),
combined AS (
   SELECT customer_id,
          total_sales,
          'web' AS source
   FROM web_sales_agg
   UNION ALL
   SELECT customer_id,
          total_sales,
          'store' AS source
   FROM store_returns_agg
)
SELECT
   customer_id,
   total_sales,
   source,
   row_number() OVER (PARTITION BY source ORDER BY total_sales DESC) AS rank_within_source,
   (SELECT avg(i_current_price) FROM item) AS avg_item_price
FROM combined
ORDER BY source, rank_within_source
LIMIT 100
