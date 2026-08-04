WITH sampled_sales AS (
  SELECT *
  FROM web_sales TABLESAMPLE BERNOULLI (10)
),

sales_with_item AS (
  SELECT ss.ws_order_number,
         ss.ws_item_sk,
         ss.ws_bill_customer_sk,
         ss.ws_ship_customer_sk,
         ss.ws_net_paid,
         i.i_category,
         i.i_brand,
         i.i_item_id
  FROM sampled_sales ss
  JOIN item i ON ss.ws_item_sk = i.i_item_sk
),

ranked_sales AS (
  SELECT swi.*, 
         ROW_NUMBER() OVER (PARTITION BY swi.ws_bill_customer_sk ORDER BY swi.ws_net_paid DESC) AS rnk
  FROM sales_with_item swi
),

top_sales AS (
  SELECT *
  FROM ranked_sales
  WHERE rnk <= 5
),

intersect_set AS (
  SELECT c.c_customer_id, ts.ws_order_number
  FROM top_sales ts
  JOIN customer c ON ts.ws_bill_customer_sk = c.c_customer_sk
  WHERE c.c_birth_year > 1950 AND ts.i_category = 'Electronics'
),

intersect_set2 AS (
  SELECT c.c_customer_id, ws.ws_order_number
  FROM web_returns wr
  JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  WHERE c.c_birth_year > 1950
),

except_set AS (
  SELECT c.c_customer_id, ws.ws_order_number
  FROM web_sales ws
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  WHERE c.c_birth_country = 'United States'
),

except_set2 AS (
  SELECT c.c_customer_id, wr.wr_order_number
  FROM web_returns wr
  JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
  WHERE wr.wr_return_quantity > 0
),

lateral_agg AS (
  SELECT ts.ws_order_number,
         ts.ws_bill_customer_sk,
         b.brand,
         b.avg_price
  FROM top_sales ts
  CROSS JOIN LATERAL (
    SELECT i.i_brand AS brand,
           AVG(i.i_current_price) AS avg_price
    FROM item i
    WHERE i.i_item_sk = ts.ws_item_sk
    GROUP BY i.i_brand
  ) b
),

distinct_aggs AS (
  SELECT
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_items
  FROM sampled_sales ws
)

SELECT
  f.c_customer_id,
  f.ws_order_number,
  la.brand,
  la.avg_price,
  da.distinct_orders,
  da.distinct_items
FROM (
  SELECT * FROM intersect_set
  INTERSECT
  SELECT * FROM intersect_set2
  UNION ALL
  SELECT * FROM except_set
  EXCEPT
  SELECT * FROM except_set2
) f
JOIN lateral_agg la ON f.ws_order_number = la.ws_order_number
CROSS JOIN distinct_aggs da
ORDER BY f.c_customer_id, f.ws_order_number
LIMIT 100
