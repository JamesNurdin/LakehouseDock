WITH joined_data AS (
  SELECT
    d.d_year,
    cc.cc_state,
    ib.ib_upper_bound,
    ws.ws_net_profit,
    sr.sr_net_loss,
    ws.ws_net_paid,
    c.c_customer_sk,
    ws_site.web_site_id,
    r.r_reason_desc,
    ws.ws_item_sk
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  -- catalog_returns linked through the same date and time dimensions
  JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    AND cr.cr_returned_time_sk = t.t_time_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk   -- second reference to reason table
  -- web_sales linked through the same date and time dimensions
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_sold_time_sk = t.t_time_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_year = 1998
    AND cc.cc_state = 'CA'
    AND ib.ib_upper_bound <= 50000
    AND ws.ws_net_profit > 0
    AND EXISTS (
      SELECT 1
      FROM store_returns sr2
      WHERE sr2.sr_customer_sk = c.c_customer_sk
        AND sr2.sr_net_loss > 100
    )
)
SELECT
  d_year,
  web_site_id,
  r_reason_desc AS reason_desc,
  SUM(sr_net_loss) AS total_net_loss,
  SUM(ws_net_paid) AS total_net_paid,
  COUNT(DISTINCT c_customer_sk) AS unique_customers,
  AVG(ws_net_profit) AS avg_net_profit,
  (SELECT AVG(cr_return_amount) FROM catalog_returns WHERE cr_return_quantity > 0) AS avg_return_amount_overall
FROM joined_data
GROUP BY ROLLUP (d_year, web_site_id, r_reason_desc)
ORDER BY d_year NULLS LAST, web_site_id NULLS LAST, reason_desc NULLS LAST
LIMIT 100
