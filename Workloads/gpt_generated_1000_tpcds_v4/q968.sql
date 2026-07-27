WITH cat_data AS (
  SELECT
    i.i_category,
    s.s_state,
    cs.cs_sold_date_sk,
    cs.cs_quantity,
    cs.cs_net_profit,
    cs.cs_ext_discount_amt,
    CASE WHEN cs.cs_ext_discount_amt > 500 THEN 'High' ELSE 'Low' END AS discount_flag,
    p.p_promo_name
  FROM catalog_sales cs
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_return_time_sk = t.t_time_sk
  LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
  LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE cs.cs_quantity > 5
    AND cs.cs_net_profit > 0
    AND i.i_brand_id = 123
    AND p.p_discount_active = 'Y'
    AND w.w_state = 'CA'
    AND t.t_hour BETWEEN 9 AND 17
),
web_data AS (
  SELECT
    i.i_category,
    we.web_state,
    ws.ws_sold_date_sk,
    ws.ws_quantity,
    ws.ws_net_profit,
    ws.ws_ext_discount_amt,
    CASE WHEN ws.ws_ext_discount_amt > 500 THEN 'High' ELSE 'Low' END AS discount_flag,
    p.p_promo_name
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE ws.ws_quantity > 5
    AND ws.ws_net_profit > 0
    AND i.i_brand_id = 123
    AND we.web_tax_percentage = 0.05
    AND t.t_hour BETWEEN 9 AND 17
),
combined AS (
  SELECT i_category, s_state AS region, cs_sold_date_sk AS sold_date, cs_quantity AS qty,
         cs_net_profit AS profit, discount_flag, p_promo_name
  FROM cat_data
  UNION ALL
  SELECT i_category, web_state AS region, ws_sold_date_sk AS sold_date, ws_quantity AS qty,
         ws_net_profit AS profit, discount_flag, p_promo_name
  FROM web_data
)
SELECT
  region,
  i_category,
  COUNT(*) AS transactions,
  SUM(profit) AS total_profit,
  AVG(qty) AS avg_quantity,
  MIN(profit) AS min_profit,
  MAX(profit) AS max_profit,
  SUM(CASE WHEN discount_flag = 'High' THEN profit ELSE 0 END) AS high_discount_profit,
  (SELECT AVG(p_cost) FROM promotion p2 WHERE p2.p_channel_details LIKE '%structures%') AS avg_promo_cost
FROM combined
WHERE region IS NOT NULL
GROUP BY region, i_category
ORDER BY total_profit DESC
LIMIT 100
