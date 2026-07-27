WITH cr_agg AS (
  SELECT
    cc.cc_call_center_id,
    w.w_warehouse_id,
    ib.ib_income_band_sk,
    time_dim.t_hour AS hour,
    SUM(cr.cr_net_loss) AS total_cr_net_loss,
    COUNT(*) AS cr_return_cnt
  FROM catalog_returns cr
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim ON cr.cr_returned_time_sk = time_dim.t_time_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE cc.cc_country = 'United States'
    AND cc.cc_city IN ('Harmony', 'Pine Grove')
    AND w.w_zip IN ('44593', '89275')
    AND ib.ib_lower_bound >= 50000
    AND time_dim.t_hour BETWEEN 9 AND 17
  GROUP BY cc.cc_call_center_id, w.w_warehouse_id, ib.ib_income_band_sk, time_dim.t_hour
),
wr_agg AS (
  SELECT
    ib.ib_income_band_sk,
    time_dim.t_hour AS hour,
    AVG(wr.wr_net_loss) AS avg_wr_net_loss,
    COUNT(*) AS wr_return_cnt
  FROM web_returns wr
  JOIN time_dim ON wr.wr_returned_time_sk = time_dim.t_time_sk
  JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE ib.ib_upper_bound <= 100000
    AND time_dim.t_hour BETWEEN 9 AND 17
    AND hd.hd_vehicle_count >= 2
    AND wr.wr_return_tax > 20
  GROUP BY ib.ib_income_band_sk, time_dim.t_hour
)
SELECT
  cr.cc_call_center_id,
  cr.w_warehouse_id,
  cr.ib_income_band_sk,
  cr.hour,
  cr.total_cr_net_loss,
  cr.cr_return_cnt,
  wr.avg_wr_net_loss,
  wr.wr_return_cnt,
  cr.total_cr_net_loss / NULLIF(wr.avg_wr_net_loss, 0) AS loss_ratio
FROM cr_agg cr
JOIN wr_agg wr
  ON cr.ib_income_band_sk = wr.ib_income_band_sk
  AND cr.hour = wr.hour
WHERE cr.cr_return_cnt > 10
  AND wr.wr_return_cnt > 5
ORDER BY cr.total_cr_net_loss DESC
LIMIT 100
