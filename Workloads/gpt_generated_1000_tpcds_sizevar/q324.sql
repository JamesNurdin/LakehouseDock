WITH base AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    ca.ca_state,
    hd.hd_buy_potential,
    td.t_hour,
    ss.ss_sold_date_sk,
    ss.ss_ext_sales_price,
    sr.sr_return_amt,
    cr.cr_return_amount,
    ws.ws_quantity,
    ws.ws_net_profit,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    p.p_discount_active
  FROM store_sales ss
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
  JOIN catalog_returns cr ON cr.cr_returned_time_sk = td.t_time_sk
                          AND cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
                     AND ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE td.t_hour = 14
    AND ca.ca_gmt_offset = -5.00
    AND hd.hd_buy_potential = '5001-10000'
    AND p.p_discount_active = 'Y'
    AND ws.ws_quantity > 5
    AND cr.cr_return_amount > 100
)
SELECT
  b.c_customer_id,
  b.ca_state,
  b.hd_buy_potential,
  b.t_hour,
  SUM(b.ss_ext_sales_price) AS total_store_sales,
  SUM(b.sr_return_amt) AS total_store_returns,
  SUM(b.cr_return_amount) AS total_catalog_returns,
  COUNT(DISTINCT b.ws_quantity) AS distinct_quantity_counts,
  AVG(b.ws_net_profit) AS avg_web_profit,
  MIN(b.ib_lower_bound) AS min_income_lower,
  MAX(b.ib_upper_bound) AS max_income_upper,
  lo.web_orders
FROM base b
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS web_orders
    FROM web_sales ws2
    WHERE ws2.ws_bill_customer_sk = b.c_customer_sk
      AND ws2.ws_sold_date_sk = b.ss_sold_date_sk
) AS lo
GROUP BY
  b.c_customer_id,
  b.ca_state,
  b.hd_buy_potential,
  b.t_hour,
  lo.web_orders
ORDER BY total_store_sales DESC
OFFSET 0 LIMIT 100
