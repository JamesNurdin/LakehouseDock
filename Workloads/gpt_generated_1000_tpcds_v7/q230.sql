SELECT
  d.d_year,
  s.s_state,
  r.r_reason_desc,
  SUM(ss.ss_net_profit)               AS total_store_profit,
  SUM(cs.cs_net_paid)                 AS total_catalog_paid,
  COUNT(DISTINCT sr.sr_ticket_number) AS return_ticket_cnt,
  AVG(cs.cs_ext_discount_amt)         AS avg_catalog_discount
FROM date_dim d
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
  ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store_returns sr
  ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN call_center cc
  ON cc.cc_closed_date_sk = d.d_date_sk
JOIN catalog_sales cs
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN web_page wp
  ON wp.wp_customer_sk = c.c_customer_sk
  AND wp.wp_creation_date_sk = d.d_date_sk
-- Re‑use date_dim under a second alias for the ship date of catalog sales
JOIN date_dim d2
  ON cs.cs_ship_date_sk = d2.d_date_sk
-- Re‑use customer_address under a second alias for the ship address of catalog sales
JOIN customer_address ca_ship
  ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
WHERE d.d_year = 2001
GROUP BY
  d.d_year,
  s.s_state,
  r.r_reason_desc
ORDER BY
  total_store_profit DESC
