WITH store_sales_agg AS (
  SELECT
    ss_sold_time_sk,
    ss_store_sk,
    ss_promo_sk,
    ss_hdemo_sk,
    SUM(ss_net_profit) AS total_store_profit,
    SUM(ss_quantity) AS total_store_quantity,
    COUNT(*) AS store_sales_cnt
  FROM store_sales
  GROUP BY ss_sold_time_sk, ss_store_sk, ss_promo_sk, ss_hdemo_sk
),
inventory_agg AS (
  SELECT
    inv_warehouse_sk,
    SUM(inv_quantity_on_hand) AS total_inventory_qty
  FROM inventory
  GROUP BY inv_warehouse_sk
),
web_sales_agg AS (
  SELECT
    ws_order_number,
    ws_warehouse_sk,
    ws_web_page_sk,
    ws_promo_sk,
    SUM(ws_net_profit) AS total_web_profit,
    SUM(ws_quantity) AS total_web_quantity,
    COUNT(*) AS web_sales_cnt
  FROM web_sales
  GROUP BY ws_order_number, ws_warehouse_sk, ws_web_page_sk, ws_promo_sk
)
SELECT
  s.s_store_name,
  p.p_promo_name,
  hd.hd_income_band_sk,
  CASE
    WHEN hd.hd_income_band_sk >= 15 THEN 'High Income'
    ELSE 'Low Income'
  END AS income_category,
  t1.t_hour,
  ws_agg.total_web_profit,
  ss_agg.total_store_profit,
  inv_agg.total_inventory_qty,
  COUNT(DISTINCT ws_agg.ws_web_page_sk) AS distinct_web_pages,
  SUM(ws_agg.total_web_profit + ss_agg.total_store_profit) AS combined_profit
FROM store_sales_agg ss_agg
JOIN store s
  ON ss_agg.ss_store_sk = s.s_store_sk
JOIN promotion p
  ON ss_agg.ss_promo_sk = p.p_promo_sk
JOIN time_dim t1
  ON ss_agg.ss_sold_time_sk = t1.t_time_sk
JOIN household_demographics hd
  ON ss_agg.ss_hdemo_sk = hd.hd_demo_sk
JOIN web_sales_agg ws_agg
  ON ws_agg.ws_promo_sk = p.p_promo_sk
JOIN warehouse w
  ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
JOIN inventory_agg inv_agg
  ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
  ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
  ON ws_agg.ws_order_number = wr.wr_order_number
  AND wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
JOIN customer c
  ON wp.wp_customer_sk = c.c_customer_sk
WHERE
  p.p_discount_active = 'Y'
  AND hd.hd_dep_count >= 2
  AND w.w_country = 'United States'
GROUP BY
  s.s_store_name,
  p.p_promo_name,
  hd.hd_income_band_sk,
  CASE
    WHEN hd.hd_income_band_sk >= 15 THEN 'High Income'
    ELSE 'Low Income'
  END,
  t1.t_hour,
  ws_agg.total_web_profit,
  ss_agg.total_store_profit,
  inv_agg.total_inventory_qty
HAVING
  SUM(ws_agg.total_web_profit + ss_agg.total_store_profit) > 10000
ORDER BY
  combined_profit DESC
LIMIT 100
