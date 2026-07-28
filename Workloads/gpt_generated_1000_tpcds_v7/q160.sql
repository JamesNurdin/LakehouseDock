WITH store_rev AS (
  SELECT
    i.i_item_id,
    s.s_store_name AS location_name,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    'store' AS sales_channel
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year = 2002
  GROUP BY i.i_item_id, s.s_store_name
),
catalog_rev AS (
  SELECT
    i.i_item_id,
    w.w_warehouse_name AS location_name,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    'catalog' AS sales_channel
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_year = 2002
  GROUP BY i.i_item_id, w.w_warehouse_name
)
SELECT i_item_id,
       location_name,
       total_sales,
       sales_channel
FROM store_rev
UNION ALL
SELECT i_item_id,
       location_name,
       total_sales,
       sales_channel
FROM catalog_rev
ORDER BY total_sales DESC
LIMIT 100
