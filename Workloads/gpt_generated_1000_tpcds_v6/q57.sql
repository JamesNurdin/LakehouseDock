SELECT
  dr.d_year,
  dr.d_moy,
  cc.cc_name,
  ws.web_site_id,
  r_cr.r_reason_desc,
  SUM(cr.cr_net_loss)               AS total_catalog_net_loss,
  SUM(sr.sr_net_loss)               AS total_store_net_loss,
  SUM(wr.wr_net_loss)               AS total_web_net_loss,
  COUNT(*)                          AS total_transactions,
  AVG(cr.cr_return_amount)          AS avg_catalog_return_amount,
  MIN(dr.d_date)                    AS min_return_date,
  MAX(dr.d_date)                    AS max_return_date
FROM call_center cc
JOIN catalog_returns cr
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim dr
  ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN store_returns sr
  ON sr.sr_returned_date_sk = dr.d_date_sk
JOIN reason r_sr
  ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = dr.d_date_sk
JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN web_site ws
  ON ws.web_open_date_sk = dr.d_date_sk
WHERE dr.d_moy = 10
  AND dr.d_current_quarter = 'Y'
  AND dr.d_year = 2022
  AND r_cr.r_reason_desc = 'Package was damaged'
  AND cc.cc_state = 'CA'
  AND ws.web_city = 'San Francisco'
  AND ws.web_suite_number = 'Suite 350 '
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = sr.sr_item_sk
          AND cr2.cr_returned_date_sk = sr.sr_returned_date_sk
      )
GROUP BY dr.d_year, dr.d_moy, cc.cc_name, ws.web_site_id, r_cr.r_reason_desc
ORDER BY total_catalog_net_loss DESC
LIMIT 100
