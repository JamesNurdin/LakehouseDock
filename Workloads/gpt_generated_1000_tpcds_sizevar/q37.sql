SELECT
  r.r_reason_desc AS category,
  COUNT(DISTINCT sr.sr_ticket_number) AS cnt,
  SUM(sr.sr_return_amt) AS total_amount
FROM store_returns sr
RIGHT OUTER JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
WHERE sr.sr_store_sk IN (
  SELECT s2.s_store_sk
  FROM store s2
  WHERE s2.s_state = 'CA'
)
GROUP BY r.r_reason_desc

UNION

SELECT
  sm.sm_carrier AS category,
  COUNT(DISTINCT cr.cr_order_number) AS cnt,
  SUM(cr.cr_return_amount) AS total_amount
FROM catalog_returns cr
RIGHT OUTER JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE cr.cr_catalog_page_sk IN (
  SELECT cp.cp_catalog_page_sk
  FROM catalog_page cp
  WHERE cp.cp_type = 'monthly'
)
GROUP BY sm.sm_carrier

LIMIT 100
