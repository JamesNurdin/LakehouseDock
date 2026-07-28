WITH start_returns AS (
  SELECT
    cd.cd_gender AS gender,
    d.d_year AS year,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
    SUM(wr.wr_fee) AS total_fee
  FROM web_returns wr
  JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN customer_demographics cd
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN promotion p
    ON p.p_start_date_sk = d.d_date_sk
  WHERE p.p_channel_catalog = 'N'
    AND d.d_year BETWEEN 2000 AND 2002
  GROUP BY GROUPING SETS (
    (cd.cd_gender, d.d_year),
    (cd.cd_gender),
    (d.d_year),
    ()
  )
),
end_returns AS (
  SELECT
    cd.cd_gender AS gender,
    d.d_year AS year,
    COUNT(*) AS return_cnt,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_inc_tax,
    SUM(wr.wr_fee) AS total_fee
  FROM web_returns wr
  JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN customer_demographics cd
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN promotion p
    ON p.p_end_date_sk = d.d_date_sk
  WHERE p.p_channel_tv = 'N'
    AND d.d_year BETWEEN 2000 AND 2002
  GROUP BY GROUPING SETS (
    (cd.cd_gender, d.d_year),
    (cd.cd_gender),
    (d.d_year),
    ()
  )
)
SELECT
  gender,
  year,
  return_cnt,
  total_return_inc_tax,
  total_fee,
  source
FROM (
  SELECT gender, year, return_cnt, total_return_inc_tax, total_fee, 'promo_start' AS source
  FROM start_returns
  UNION ALL
  SELECT gender, year, return_cnt, total_return_inc_tax, total_fee, 'promo_end' AS source
  FROM end_returns
) combined
ORDER BY
  gender,
  year,
  source
LIMIT 100
