WITH
  sales_agg AS (
    SELECT
      ws_warehouse_sk,
      ws_web_site_sk,
      ws_sold_time_sk,
      SUM(ws_net_paid_inc_ship_tax) AS total_sales,
      SUM(ws_ext_discount_amt) AS total_discount,
      COUNT(*) AS order_cnt
    FROM web_sales
    WHERE ws_net_paid_inc_ship_tax > 2000
      AND ws_ext_discount_amt < 3000
      AND ws_quantity >= 2
      AND ws_list_price > 50
    GROUP BY ws_warehouse_sk, ws_web_site_sk, ws_sold_time_sk
  ),
  warehouse_keys AS (
    SELECT w_warehouse_sk
    FROM warehouse
    WHERE w_gmt_offset = -5.00
  ),
  high_sales_warehouse_keys AS (
    SELECT DISTINCT ws_warehouse_sk AS w_warehouse_sk
    FROM web_sales
    WHERE ws_net_paid_inc_ship_tax > 3000
  ),
  warehouse_excluding_high AS (
    SELECT w_warehouse_sk
    FROM warehouse_keys
    EXCEPT
    SELECT w_warehouse_sk FROM high_sales_warehouse_keys
  ),
  site_keys AS (
    SELECT web_site_sk
    FROM web_site
    WHERE web_country = 'United States'
  ),
  site_active_keys AS (
    SELECT web_site_sk
    FROM web_site
    WHERE web_gmt_offset BETWEEN -8.00 AND -4.00
  ),
  site_intersection AS (
    SELECT web_site_sk
    FROM site_keys
    INTERSECT
    SELECT web_site_sk
    FROM site_active_keys
  )
SELECT
  ws_agg.ws_warehouse_sk,
  wh.w_warehouse_name,
  ws_agg.ws_web_site_sk,
  ws.web_name,
  ws_agg.total_sales,
  ws_agg.total_discount,
  ws_agg.order_cnt,
  RANK() OVER (PARTITION BY ws_agg.ws_web_site_sk ORDER BY ws_agg.total_sales DESC) AS sales_rank,
  CASE
    WHEN ws_agg.total_discount / NULLIF(ws_agg.total_sales, 0) > 0.15 THEN 'High Discount'
    ELSE 'Standard Discount'
  END AS discount_category
FROM sales_agg ws_agg
RIGHT JOIN web_site ws
  ON ws_agg.ws_web_site_sk = ws.web_site_sk
LEFT JOIN warehouse wh
  ON ws_agg.ws_warehouse_sk = wh.w_warehouse_sk
LEFT JOIN time_dim td
  ON ws_agg.ws_sold_time_sk = td.t_time_sk
WHERE ws.web_site_sk IN (SELECT web_site_sk FROM site_intersection)
  AND (wh.w_warehouse_sk IS NULL OR wh.w_warehouse_sk IN (SELECT w_warehouse_sk FROM warehouse_excluding_high))
  AND td.t_hour BETWEEN 8 AND 18
  AND td.t_am_pm = 'PM'
  AND td.t_second <> 0
  AND td.t_shift IS NOT NULL
ORDER BY ws_agg.ws_web_site_sk, sales_rank
LIMIT 100
