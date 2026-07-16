SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    rcd.cd_gender AS returning_gender,
    rcd.cd_marital_status AS returning_marital_status,
    rhd.hd_income_band_sk AS returning_income_band,
    fcd.cd_gender AS refunded_gender,
    fcd.cd_marital_status AS refunded_marital_status,
    fhd.hd_income_band_sk AS refunded_income_band,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(cr.cr_net_loss) DESC) AS loss_rank
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN customer_demographics rcd
  ON cr.cr_returning_cdemo_sk = rcd.cd_demo_sk
JOIN customer_demographics fcd
  ON cr.cr_refunded_cdemo_sk = fcd.cd_demo_sk
JOIN household_demographics rhd
  ON cr.cr_returning_hdemo_sk = rhd.hd_demo_sk
JOIN household_demographics fhd
  ON cr.cr_refunded_hdemo_sk = fhd.hd_demo_sk
WHERE d.d_year = 2001
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    rcd.cd_gender,
    rcd.cd_marital_status,
    rhd.hd_income_band_sk,
    fcd.cd_gender,
    fcd.cd_marital_status,
    fhd.hd_income_band_sk
ORDER BY total_net_loss DESC
LIMIT 100
