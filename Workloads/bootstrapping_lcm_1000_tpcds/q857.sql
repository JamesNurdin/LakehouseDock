SELECT
    dr.d_year * 100 + dr.d_moy AS year_month,
    sm.sm_type,
    s.s_state,
    wp.wp_type,
    CASE WHEN cr.cr_fee >= 10 THEN 'HighFee' ELSE 'LowFee' END AS fee_category,
    COUNT(*) AS total_returns,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(CASE WHEN cr.cr_fee >= 10 THEN 1 ELSE 0 END) AS high_fee_return_count,
    SUM(CASE WHEN cr.cr_fee < 10 THEN 1 ELSE 0 END) AS low_fee_return_count,
    ROUND(SUM(cr.cr_net_loss) / NULLIF(COUNT(*), 0), 2) AS avg_loss_per_return
FROM catalog_returns cr
JOIN date_dim dr
  ON cr.cr_returned_date_sk = dr.d_date_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s
  ON s.s_closed_date_sk = dr.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = dr.d_date_sk
WHERE dr.d_year BETWEEN 1998 AND 2002
  AND cr.cr_net_loss IS NOT NULL
GROUP BY
    dr.d_year,
    dr.d_moy,
    sm.sm_type,
    s.s_state,
    wp.wp_type,
    CASE WHEN cr.cr_fee >= 10 THEN 'HighFee' ELSE 'LowFee' END
HAVING COUNT(*) > 5
ORDER BY total_net_loss DESC
LIMIT 100
