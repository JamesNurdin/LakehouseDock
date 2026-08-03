WITH sales_agg AS (
  SELECT
    cs.cs_order_number,
    cs.cs_ext_sales_price,
    cs.cs_ext_ship_cost,
    ws.ws_order_number,
    ws.ws_ext_sales_price,
    i.i_category,
    s.s_store_name,
    s.s_store_sk,
    sm.sm_type,
    w.w_warehouse_name,
    t.t_hour
  FROM catalog_page cp
  JOIN catalog_sales cs ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_time_sk = t.t_time_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                     AND ws.ws_sold_time_sk = t.t_time_sk
                     AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
                     AND ws.ws_warehouse_sk = w.w_warehouse_sk
  WHERE cp.cp_department = 'Books'
    AND cp.cp_catalog_page_number BETWEEN 1 AND 5
    AND i.i_brand = 'Brand#12'
    AND sm.sm_type = 'AIR'
    AND w.w_state = 'CA'
    AND t.t_hour BETWEEN 8 AND 12
    AND s.s_state = 'CA'
)
SELECT
  agg.distinct_catalog_orders,
  agg.distinct_web_orders,
  agg.avg_catalog_sales,
  agg.total_web_sales,
  agg.max_ship_cost_high_wholesale,
  agg.has_west_coast_store,
  ls.store_sales_cnt
FROM (
   SELECT
     i_category,
     s_store_name,
     s_store_sk,
     sm_type,
     w_warehouse_name,
     t_hour,
     COUNT(DISTINCT cs_order_number) AS distinct_catalog_orders,
     COUNT(DISTINCT ws_order_number) AS distinct_web_orders,
     AVG(cs_ext_sales_price) AS avg_catalog_sales,
     SUM(ws_ext_sales_price) AS total_web_sales,
     (
       SELECT MAX(cs_ext_ship_cost)
       FROM catalog_sales
       WHERE cs_wholesale_cost > 50
     ) AS max_ship_cost_high_wholesale,
     EXISTS (
       SELECT 1
       FROM store
       WHERE s_gmt_offset = -8.00
         AND s_country = 'United States'
     ) AS has_west_coast_store
   FROM sales_agg
   GROUP BY i_category, s_store_name, s_store_sk, sm_type, w_warehouse_name, t_hour
   HAVING SUM(cs_ext_sales_price) > 10000
) agg
CROSS JOIN LATERAL (
   SELECT COUNT(*) AS store_sales_cnt
   FROM store_sales ss2
   WHERE ss2.ss_store_sk = agg.s_store_sk
) ls
ORDER BY agg.total_web_sales DESC
LIMIT 100
