WITH joined_data AS (
  SELECT
    cc.cc_call_center_id,
    dd.d_year AS d_year,
    cr.cr_return_amount,
    cr.cr_net_loss,
    wr.wr_return_amt,
    wr.wr_net_loss,
    cc.cc_state,
    cp.cp_type,
    sm.sm_carrier,
    hd.hd_vehicle_count
  FROM catalog_returns cr
  JOIN date_dim dd
    ON cr.cr_returned_date_sk = dd.d_date_sk
  JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN household_demographics hd
    ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN web_returns wr
    ON wr.wr_returned_date_sk = dd.d_date_sk
   AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE dd.d_year = 2002
    AND cc.cc_state = 'CA'
    AND cp.cp_type = 'C'
    AND sm.sm_carrier = 'UPS'
    AND hd.hd_vehicle_count >= 1
    AND cr.cr_return_amount > 100
    AND wr.wr_return_quantity > 0
),
agg_by_cc_year AS (
  SELECT
    cc_call_center_id,
    d_year,
    SUM(cr_return_amount) AS cat_return_amount_sum,
    SUM(wr_return_amt) AS web_return_amount_sum,
    SUM(cr_net_loss + wr_net_loss) AS total_net_loss,
    COUNT(*) AS total_returns
  FROM joined_data
  GROUP BY cc_call_center_id, d_year
  HAVING COUNT(*) > 5
)
SELECT
  cc_call_center_id,
  AVG(total_net_loss) AS avg_yearly_net_loss,
  SUM(cat_return_amount_sum) AS total_catalog_return_amount,
  SUM(web_return_amount_sum) AS total_web_return_amount
FROM agg_by_cc_year
GROUP BY cc_call_center_id
HAVING AVG(total_net_loss) > 1000
ORDER BY avg_yearly_net_loss DESC
LIMIT 10
