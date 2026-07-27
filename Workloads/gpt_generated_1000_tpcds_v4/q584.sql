WITH store_sales_agg AS (
  SELECT i.i_item_id,
         i.i_item_desc,
         SUM(ss.ss_ext_sales_price) AS total_sales,
         COUNT(DISTINCT ss.ss_ticket_number) AS order_count,
         'store' AS source
  FROM tpcds.store_sales ss
  JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
  JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year = 2001
    AND s.s_state = 'CA'
  GROUP BY i.i_item_id, i.i_item_desc
),
catalog_sales_agg AS (
  SELECT i.i_item_id,
         i.i_item_desc,
         SUM(cs.cs_ext_sales_price) AS total_sales,
         COUNT(DISTINCT cs.cs_order_number) AS order_count,
         'catalog' AS source
  FROM tpcds.catalog_sales cs
  JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
  JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year = 2001
    AND sm.sm_carrier = 'ORIENTAL'
  GROUP BY i.i_item_id, i.i_item_desc
)
SELECT *
FROM store_sales_agg
UNION ALL
SELECT *
FROM catalog_sales_agg
ORDER BY total_sales DESC
LIMIT 100
