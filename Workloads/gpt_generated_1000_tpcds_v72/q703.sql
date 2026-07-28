WITH refunded_returns AS (
  SELECT
    dd.d_year,
    cd.cd_gender,
    hd.hd_income_band_sk,
    SUM(cr.cr_return_amount) AS total_return_amount,
    'refunded' AS source
  FROM catalog_returns cr
  JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  WHERE cr.cr_refunded_cash > 500
  GROUP BY dd.d_year, cd.cd_gender, hd.hd_income_band_sk
),
returning_returns AS (
  SELECT
    dd.d_year,
    cd.cd_gender,
    hd.hd_income_band_sk,
    SUM(cr.cr_return_amount) AS total_return_amount,
    'returning' AS source
  FROM catalog_returns cr
  JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
  JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
  WHERE cr.cr_return_amount > 200
  GROUP BY dd.d_year, cd.cd_gender, hd.hd_income_band_sk
)
SELECT *
FROM refunded_returns
UNION ALL
SELECT *
FROM returning_returns
ORDER BY d_year DESC, total_return_amount DESC
LIMIT 100
