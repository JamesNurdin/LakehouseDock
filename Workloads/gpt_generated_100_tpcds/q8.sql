SELECT
    cp.cp_department,
    sm.sm_ship_mode_id,
    t.t_hour,
    cd.cd_gender,
    r.r_reason_desc,
    COUNT(*) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_qty
FROM catalog_returns cr
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim t
  ON cr.cr_returned_time_sk = t.t_time_sk
JOIN customer_demographics cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
WHERE cp.cp_department = 'Electronics'
  AND sm.sm_type = 'AIR'
GROUP BY cp.cp_department, sm.sm_ship_mode_id, t.t_hour, cd.cd_gender, r.r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 10
