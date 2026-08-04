WITH first_part AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_paid,
    ws.ws_net_profit,
    p.p_promo_name,
    w.w_warehouse_name,
    sm.sm_ship_mode_id,
    r.r_reason_desc,
    td.t_time,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY ws.ws_net_paid DESC) AS sales_rank
  FROM web_sales ws
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  FULL OUTER JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  FULL OUTER JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
  WHERE ws.ws_quantity > 5
    AND p.p_purpose = 'Unknown'
    AND td.t_time BETWEEN 6 AND 15
    AND i.inv_quantity_on_hand > 0
    AND w.w_gmt_offset >= -5.00
    AND cr.cr_return_amount > 0
),
second_part AS (
  SELECT
    ws.ws_order_number,
    ws.ws_net_paid,
    ws.ws_net_profit,
    p.p_promo_name,
    w.w_warehouse_name,
    sm.sm_ship_mode_id,
    r.r_reason_desc,
    td.t_time,
    CASE WHEN ws.ws_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY ws.ws_net_paid DESC) AS sales_rank
  FROM web_sales ws TABLESAMPLE BERNOULLI (10)
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  FULL OUTER JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
  FULL OUTER JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
  JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
  JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
  WHERE ws.ws_quantity > 10
    AND p.p_purpose = 'Unknown'
    AND td.t_time BETWEEN 6 AND 15
    AND i.inv_quantity_on_hand > 5
    AND w.w_gmt_offset >= -5.00
    AND cr.cr_return_amount > 5
)
SELECT *
FROM (
  SELECT * FROM first_part
  UNION DISTINCT
  SELECT * FROM second_part
) combined
ORDER BY sales_rank
LIMIT 100
