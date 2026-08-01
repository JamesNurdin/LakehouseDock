WITH
  store_data AS (
    SELECT
      ss.ss_sold_time_sk               AS time_sk,
      ss.ss_customer_sk                AS customer_sk,
      ss.ss_item_sk                    AS item_sk,
      i.i_brand,
      i.i_category,
      ss.ss_ext_sales_price            AS sales_price,
      MAP(ARRAY['qty', 'price'], ARRAY[ss.ss_quantity, CAST(ss.ss_ext_sales_price AS double)]) AS kv_map
    FROM tpcds.store_sales ss
    JOIN tpcds.time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    WHERE t.t_hour BETWEEN 8 AND 12
  ),
  catalog_data AS (
    SELECT
      cs.cs_sold_time_sk               AS time_sk,
      cs.cs_bill_customer_sk            AS customer_sk,
      cs.cs_item_sk                     AS item_sk,
      i.i_brand,
      i.i_category,
      cs.cs_ext_sales_price             AS sales_price,
      MAP(ARRAY['qty', 'price'], ARRAY[cs.cs_quantity, CAST(cs.cs_ext_sales_price AS double)]) AS kv_map
    FROM tpcds.catalog_sales cs
    JOIN tpcds.time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    WHERE t.t_hour BETWEEN 8 AND 12
  ),
  full_joined AS (
    SELECT
      COALESCE(s.time_sk, c.time_sk)                       AS time_sk,
      COALESCE(s.customer_sk, c.customer_sk)               AS customer_sk,
      COALESCE(s.item_sk, c.item_sk)                       AS item_sk,
      COALESCE(s.i_brand, c.i_brand)                       AS i_brand,
      COALESCE(s.i_category, c.i_category)                 AS i_category,
      COALESCE(s.sales_price, c.sales_price)               AS sales_price,
      COALESCE(s.kv_map, c.kv_map)                         AS kv_map
    FROM store_data s
    FULL OUTER JOIN catalog_data c
      ON s.time_sk = c.time_sk
     AND s.customer_sk = c.customer_sk
     AND s.item_sk = c.item_sk
  )
SELECT
  u.time_sk,
  u.customer_sk,
  u.i_brand,
  u.i_category,
  CASE
    WHEN u.sales_price > 1000 THEN 'High'
    WHEN u.sales_price BETWEEN 500 AND 1000 THEN 'Medium'
    ELSE 'Low'
  END AS sales_level,
  (
    SELECT COUNT(*)
    FROM tpcds.catalog_sales cs2
    WHERE cs2.cs_bill_customer_sk = u.customer_sk
  ) AS total_customer_orders,
  kv.attr,
  kv.val,
  ROW_NUMBER() OVER (PARTITION BY u.i_category ORDER BY u.sales_price DESC) AS category_rank,
  SUM(u.sales_price) OVER (PARTITION BY u.time_sk ORDER BY u.time_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales
FROM (
  SELECT time_sk, customer_sk, i_brand, i_category, sales_price, kv_map
  FROM full_joined
  UNION ALL
  SELECT time_sk, customer_sk, i_brand, i_category, sales_price, kv_map
  FROM catalog_data
) u
CROSS JOIN UNNEST(u.kv_map) AS kv(attr, val)
ORDER BY u.time_sk DESC, u.sales_price DESC
LIMIT 100
