WITH agg AS (
  SELECT
    cd_ref.cd_gender,
    sm.sm_type,
    ib.ib_income_band_sk,
    sm.sm_ship_mode_sk AS ship_mode_sk,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_tax) AS avg_return_tax,
    COUNT(*) AS return_cnt,
    MIN(cr.cr_return_ship_cost) AS min_ship_cost,
    MAX(cr.cr_net_loss) AS max_net_loss,
    (
      SELECT AVG(cr2.cr_return_amount)
      FROM catalog_returns cr2
      WHERE cr2.cr_ship_mode_sk = sm.sm_ship_mode_sk
    ) AS avg_return_amount_by_ship_mode
  FROM catalog_returns cr
  JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN income_band ib
    ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
  WHERE cd_ref.cd_credit_rating = 'Good'
    AND cd_ref.cd_dep_employed_count >= 2
    AND sm.sm_code = 'AIR'
    AND sm.sm_contract = 'P7FBIt8yd'
    AND ib.ib_upper_bound <= 50000
    AND cr.cr_return_amount > 1000
    AND cr.cr_return_quantity BETWEEN 1 AND 5
  GROUP BY cd_ref.cd_gender, sm.sm_type, ib.ib_income_band_sk, sm.sm_ship_mode_sk
  HAVING SUM(cr.cr_return_amount) > 5000
)
SELECT
  cd_gender,
  sm_type,
  ib_income_band_sk,
  total_return_amount,
  avg_return_tax,
  return_cnt,
  min_ship_cost,
  max_net_loss,
  avg_return_amount_by_ship_mode,
  ROW_NUMBER() OVER (PARTITION BY sm_type ORDER BY total_return_amount DESC) AS rn
FROM agg
ORDER BY total_return_amount DESC
LIMIT 100
