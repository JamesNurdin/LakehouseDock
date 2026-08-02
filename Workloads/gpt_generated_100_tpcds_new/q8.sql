WITH store_sales_agg AS (
  SELECT
    ss.ss_store_sk,
    ss.ss_sold_date_sk,
    ss.ss_promo_sk,
    SUM(ss.ss_net_paid) AS total_net_paid,
    SUM(ss.ss_quantity) AS total_quantity,
    COUNT(*) AS sales_cnt
  FROM store_sales ss
  GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_promo_sk
)
SELECT
  s.s_store_id,
  d.d_date,
  p.p_promo_name,
  sm.sm_carrier,
  ca.ca_state,
  cd.cd_credit_rating,
  agg.total_net_paid,
  agg.total_quantity,
  agg.sales_cnt,
  SUM(cr.cr_return_amount) AS total_return_amount,
  COUNT(DISTINCT cr.cr_order_number) AS return_cnt,
  SUM(ws.ws_quantity) AS total_web_quantity,
  AVG(ws.ws_sales_price) AS avg_web_sales_price,
  ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY agg.total_net_paid DESC) AS store_sales_rank
FROM store_sales_agg agg
JOIN store s ON agg.ss_store_sk = s.s_store_sk
JOIN date_dim d ON agg.ss_sold_date_sk = d.d_date_sk
JOIN promotion p ON agg.ss_promo_sk = p.p_promo_sk
JOIN inventory i ON d.d_date_sk = i.inv_date_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND sm.sm_carrier = 'UPS'
  AND p.p_discount_active = 'Y'
  AND cd.cd_credit_rating = 'High Risk'
  AND i.inv_quantity_on_hand > 100
GROUP BY
  s.s_store_id,
  d.d_date,
  p.p_promo_name,
  sm.sm_carrier,
  ca.ca_state,
  cd.cd_credit_rating,
  agg.total_net_paid,
  agg.total_quantity,
  agg.sales_cnt
ORDER BY total_net_paid DESC
LIMIT 100
