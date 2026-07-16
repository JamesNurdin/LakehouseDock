WITH catalog_return_summary AS (
  SELECT
    cr.cr_reason_sk,
    cr.cr_call_center_sk,
    d.d_year AS year,
    d.d_moy AS month,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS num_returns,
    AVG(cr.cr_return_quantity) AS avg_quantity
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  WHERE d.d_year = 2001
    AND cc.cc_state = 'TN'
  GROUP BY cr.cr_reason_sk, cr.cr_call_center_sk, d.d_year, d.d_moy
)
SELECT
  r.r_reason_desc AS reason,
  cc.cc_city AS city,
  crs.year,
  crs.month,
  crs.total_return_amount,
  crs.total_net_loss,
  crs.num_returns,
  crs.avg_quantity,
  RANK() OVER (PARTITION BY crs.year, crs.month ORDER BY crs.total_net_loss DESC) AS net_loss_rank
FROM catalog_return_summary crs
JOIN reason r ON crs.cr_reason_sk = r.r_reason_sk
JOIN call_center cc ON crs.cr_call_center_sk = cc.cc_call_center_sk
WHERE crs.total_return_amount > 5000
ORDER BY crs.total_return_amount DESC
LIMIT 100
