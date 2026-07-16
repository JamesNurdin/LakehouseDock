SELECT
  d.d_year,
  d.d_month_seq,
  t.t_hour,
  s.s_state AS store_state,
  ca.ca_state AS address_state,
  i.i_category,
  i.i_brand,
  cd.cd_gender,
  hd.hd_income_band_sk,
  p.p_promo_id,
  SUM(ss.ss_net_paid) AS total_net_paid,
  SUM(ss.ss_net_profit) AS total_net_profit,
  SUM(ss.ss_quantity) AS total_quantity,
  COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
  AVG(ss.ss_ext_discount_amt) AS avg_discount_amount,
  COUNT(DISTINCT p.p_promo_id) AS distinct_promo_ids
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
GROUP BY
  d.d_year,
  d.d_month_seq,
  t.t_hour,
  s.s_state,
  ca.ca_state,
  i.i_category,
  i.i_brand,
  cd.cd_gender,
  hd.hd_income_band_sk,
  p.p_promo_id
ORDER BY total_net_paid DESC
LIMIT 100
