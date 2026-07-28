WITH ss_agg AS (
  SELECT
    ss_item_sk,
    ss_customer_sk,
    ss_ticket_number,
    SUM(ss_net_paid) AS ss_total_net_paid,
    COUNT(*) AS ss_sales_cnt
  FROM tpcds.store_sales
  WHERE ss_quantity > 0
  GROUP BY ss_item_sk, ss_customer_sk, ss_ticket_number
),
ws_agg AS (
  SELECT
    ws_item_sk,
    ws_bill_customer_sk,
    ws_web_page_sk,
    ws_web_site_sk,
    ws_ship_mode_sk,
    ws_promo_sk,
    SUM(ws_net_paid) AS ws_total_net_paid,
    COUNT(*) AS ws_sales_cnt
  FROM tpcds.web_sales
  WHERE ws_quantity > 0
  GROUP BY ws_item_sk, ws_bill_customer_sk, ws_web_page_sk, ws_web_site_sk, ws_ship_mode_sk, ws_promo_sk
)
SELECT
  c.c_customer_id,
  ca.ca_city,
  cd.cd_gender,
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  p.p_promo_name,
  sm.sm_type,
  SUM(ss_agg.ss_total_net_paid) AS total_store_net_paid,
  SUM(ss_agg.ss_sales_cnt)   AS total_store_sales_cnt,
  SUM(ws_agg.ws_total_net_paid) AS total_web_net_paid,
  SUM(ws_agg.ws_sales_cnt)   AS total_web_sales_cnt,
  SUM(sr.sr_return_amt)      AS total_store_return_amount,
  SUM(cr.cr_return_amount)   AS total_catalog_return_amount,
  COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders
FROM ss_agg
JOIN tpcds.store_returns sr
  ON sr.sr_item_sk = ss_agg.ss_item_sk
 AND sr.sr_ticket_number = ss_agg.ss_ticket_number
JOIN tpcds.customer c
  ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN tpcds.catalog_returns cr
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca
  ON c.c_current_addr_sk = ca.ca_address_sk
JOIN tpcds.customer_demographics cd
  ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN ws_agg
  ON ws_agg.ws_bill_customer_sk = c.c_customer_sk
JOIN tpcds.promotion p
  ON ws_agg.ws_promo_sk = p.p_promo_sk
JOIN tpcds.ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.web_page wp
  ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site ws
  ON ws_agg.ws_web_site_sk = ws.web_site_sk
WHERE
  ca.ca_location_type = 'single family' AND
  ca.ca_state = 'CA' AND
  cd.cd_gender = 'F' AND
  hd.hd_vehicle_count >= 2 AND
  ib.ib_upper_bound <= 80000 AND
  p.p_discount_active = 'Y' AND
  sm.sm_type = 'AIR'
GROUP BY
  c.c_customer_id,
  ca.ca_city,
  cd.cd_gender,
  hd.hd_buy_potential,
  ib.ib_lower_bound,
  p.p_promo_name,
  sm.sm_type
ORDER BY total_store_net_paid DESC
LIMIT 100
