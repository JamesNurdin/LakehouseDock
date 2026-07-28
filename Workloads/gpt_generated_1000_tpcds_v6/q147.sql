WITH base AS (
   SELECT
     c.c_customer_sk,
     c.c_first_name,
     c.c_last_name,
     ca.ca_state AS ca_state,
     ib.ib_lower_bound AS ib_lower_bound,
     SUM(sr.sr_net_loss) AS total_store_net_loss,
     SUM(cr.cr_net_loss) AS total_catalog_net_loss,
     SUM(ws.ws_net_paid) AS total_web_paid,
     COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
     COUNT(DISTINCT cr.cr_order_number) AS catalog_return_cnt,
     COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
   FROM store_returns sr
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN catalog_returns cr ON cr.cr_returning_customer_sk = c.c_customer_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
   WHERE
     cc.cc_gmt_offset > 0
     AND sm.sm_contract = 'OrDuVy2H'
     AND ca.ca_zip = '57783'
     AND ib.ib_lower_bound >= 30000
     AND w.w_state = 'CA'
     AND r.r_reason_desc LIKE '%defect%'
   GROUP BY
     c.c_customer_sk,
     c.c_first_name,
     c.c_last_name,
     ca.ca_state,
     ib.ib_lower_bound
),
filtered AS (
   SELECT
     b.*, 
     (b.total_web_paid - b.total_store_net_loss - b.total_catalog_net_loss) AS net_contribution,
     RANK() OVER (PARTITION BY b.ca_state ORDER BY (b.total_web_paid - b.total_store_net_loss - b.total_catalog_net_loss) DESC) AS state_rank
   FROM base b
   WHERE NOT EXISTS (
       SELECT 1
       FROM store_returns sr2
       WHERE sr2.sr_customer_sk = b.c_customer_sk
         AND sr2.sr_return_quantity > 10
   )
)
SELECT
  f.c_customer_sk,
  f.c_first_name,
  f.c_last_name,
  f.ca_state,
  f.ib_lower_bound,
  f.total_store_net_loss,
  f.total_catalog_net_loss,
  f.total_web_paid,
  f.net_contribution,
  f.state_rank
FROM filtered f
WHERE f.state_rank <= 5
ORDER BY f.net_contribution DESC
LIMIT 100
