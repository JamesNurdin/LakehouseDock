SELECT
  d.d_year,
  i.i_category,
  w.w_state,
  sm.sm_type,
  p.p_promo_name,
  cd.cd_gender,
  hd.hd_buy_potential,
  SUM(ws.ws_ext_sales_price) AS total_sales,
  SUM(ws.ws_net_profit) AS total_profit,
  AVG(ws.ws_ext_discount_amt) AS avg_discount,
  COUNT(DISTINCT ws.ws_order_number) AS orders
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year BETWEEN 2000 AND 2002
  AND p.p_discount_active = 'Y'
  AND w.w_state IS NOT NULL
GROUP BY
  d.d_year,
  i.i_category,
  w.w_state,
  sm.sm_type,
  p.p_promo_name,
  cd.cd_gender,
  hd.hd_buy_potential
ORDER BY total_sales DESC
LIMIT 100
