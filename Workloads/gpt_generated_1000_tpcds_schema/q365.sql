WITH sales_with_returns AS (
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_sold_time_sk,
    ws.ws_item_sk,
    ws.ws_order_number,
    ws.ws_quantity,
    ws.ws_net_profit,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    t.t_hour,
    p.p_promo_name,
    w.w_warehouse_name,
    sm.sm_type,
    ib.ib_upper_bound,
    cr.cr_return_ship_cost,
    r1.r_reason_desc AS store_reason,
    r2.r_reason_desc AS catalog_reason,
    wr.wr_return_quantity,
    inv.inv_quantity_on_hand
  FROM web_sales ws
  JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns sr
    ON sr.sr_return_time_sk = t.t_time_sk
  LEFT JOIN reason r1
    ON sr.sr_reason_sk = r1.r_reason_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_returned_time_sk = t.t_time_sk
  LEFT JOIN reason r2
    ON cr.cr_reason_sk = r2.r_reason_sk
  LEFT JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
  LEFT JOIN warehouse w_cr
    ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
  LEFT JOIN customer c_ref
    ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
  LEFT JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  LEFT JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
  LEFT JOIN web_returns wr
    ON wr.wr_returned_time_sk = t.t_time_sk
   AND wr.wr_item_sk = ws.ws_item_sk
  LEFT JOIN reason r3
    ON wr.wr_reason_sk = r3.r_reason_sk
  LEFT JOIN web_page wp_wr
    ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
  LEFT JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE c.c_preferred_cust_flag = 'Y'
    AND ib.ib_upper_bound >= 50000
    AND w.w_city = 'Spring'
    AND sm.sm_type = 'AIR'
    AND cr.cr_return_ship_cost > 1000
    AND r1.r_reason_desc LIKE '%color%'
    AND ws.ws_quantity > 2
)
SELECT
  s.c_customer_id,
  s.c_first_name,
  s.c_last_name,
  s.ws_order_number,
  s.ws_quantity,
  s.ws_net_profit,
  SUM(s.ws_net_profit) OVER (PARTITION BY s.c_customer_id ORDER BY s.ws_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_profit,
  ROW_NUMBER() OVER (PARTITION BY s.c_customer_id ORDER BY s.ws_sold_date_sk DESC) AS rn,
  LAG(s.ws_net_profit) OVER (PARTITION BY s.c_customer_id ORDER BY s.ws_sold_date_sk) AS prev_profit,
  rc.return_cnt
FROM sales_with_returns s
LEFT JOIN LATERAL (
  SELECT COUNT(*) AS return_cnt
  FROM web_returns wr2
  WHERE wr2.wr_item_sk = s.ws_item_sk
    AND wr2.wr_returned_time_sk = s.ws_sold_time_sk
) rc ON TRUE
ORDER BY running_profit DESC
LIMIT 100
