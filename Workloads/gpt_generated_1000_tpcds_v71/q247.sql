WITH returns_agg AS (
   SELECT
     sr.sr_customer_sk AS customer_sk,
     SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
     COUNT(*) AS return_cnt
   FROM store_returns sr
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   GROUP BY sr.sr_customer_sk
)
SELECT
   c.c_customer_id,
   d_sales.d_year,
   SUM(ss.ss_net_paid) AS total_sales,
   COUNT(DISTINCT ss.ss_ticket_number) AS orders,
   hd.hd_buy_potential,
   ib.ib_lower_bound,
   ib.ib_upper_bound,
   cc.cc_name,
   cp.cp_type,
   wp.wp_url,
   sm.sm_carrier,
   r.r_reason_desc,
   ra.total_return_amt,
   ra.return_cnt
FROM store_sales ss
JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d_sales.d_date_sk
JOIN catalog_page cp ON cp.cp_end_date_sk = d_sales.d_date_sk
JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN returns_agg ra ON ra.customer_sk = c.c_customer_sk
WHERE NOT EXISTS (
    SELECT 1 FROM catalog_page cp_ex
    WHERE cp_ex.cp_start_date_sk = d_sales.d_date_sk
      AND cp_ex.cp_type = 'Special'
)
GROUP BY
   c.c_customer_id,
   d_sales.d_year,
   hd.hd_buy_potential,
   ib.ib_lower_bound,
   ib.ib_upper_bound,
   cc.cc_name,
   cp.cp_type,
   wp.wp_url,
   sm.sm_carrier,
   r.r_reason_desc,
   ra.total_return_amt,
   ra.return_cnt
ORDER BY total_sales DESC
LIMIT 100
