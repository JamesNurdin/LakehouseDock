WITH sales_store AS (
  SELECT ss.ss_item_sk,
         i.i_item_id,
         SUM(ss.ss_ext_sales_price) AS total_sales_amount,
         SUM(ss.ss_quantity)        AS total_qty
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  WHERE td.t_shift = 'first'
    AND td.t_hour BETWEEN 8 AND 12
  GROUP BY ss.ss_item_sk, i.i_item_id
),
sales_catalog AS (
  SELECT cs.cs_item_sk,
         i.i_item_id,
         SUM(cs.cs_ext_sales_price) AS total_sales_amount,
         SUM(cs.cs_quantity)        AS total_qty
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  WHERE td.t_shift = 'first'
    AND td.t_hour BETWEEN 8 AND 12
  GROUP BY cs.cs_item_sk, i.i_item_id
),
returns AS (
  SELECT sr.sr_item_sk,
         i.i_item_id,
         SUM(sr.sr_return_quantity) AS total_return_qty
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  GROUP BY sr.sr_item_sk, i.i_item_id
),
intersect_items AS (
  SELECT i_item_id
  FROM sales_store
  INTERSECT
  SELECT i_item_id
  FROM sales_catalog
),
except_items AS (
  SELECT i_item_id
  FROM sales_store
  EXCEPT
  SELECT i_item_id
  FROM returns
),
combined_items AS (
  SELECT i_item_id FROM intersect_items
  UNION
  SELECT i_item_id FROM except_items
)
SELECT ci.i_item_id,
       u.metric_type,
       u.metric_value
FROM combined_items ci
JOIN sales_store ss ON ci.i_item_id = ss.i_item_id
CROSS JOIN LATERAL (
    SELECT ARRAY[ss.total_sales_amount, ss.total_qty] AS arr
) a
CROSS JOIN UNNEST(a.arr) WITH ORDINALITY AS u(metric_value, metric_type)
ORDER BY u.metric_value DESC
LIMIT 100
