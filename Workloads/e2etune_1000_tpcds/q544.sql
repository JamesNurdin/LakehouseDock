WITH cd_agg AS (
  SELECT
    cd_education_status,
    cd_gender,
    AVG(cd_purchase_estimate) AS avg_purchase,
    SUM(cd_dep_employed_count) AS total_emp_dep,
    COUNT(*) AS demo_cnt
  FROM customer_demographics
  WHERE cd_marital_status IN ('M', 'S')
    AND cd_purchase_estimate >= 1000
  GROUP BY cd_education_status, cd_gender
),
ib_agg AS (
  SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound
  FROM income_band
),
td_agg AS (
  SELECT
    t_hour,
    t_shift,
    COUNT(*) AS shift_cnt
  FROM time_dim
  WHERE t_hour BETWEEN 9 AND 17
  GROUP BY t_hour, t_shift
),
ws_agg AS (
  SELECT
    AVG(web_tax_percentage) AS avg_tax_pct,
    COUNT(*) AS site_cnt
  FROM web_site
  WHERE web_open_date_sk > 20200101
)
SELECT
  cd.cd_education_status,
  cd.cd_gender,
  cd.avg_purchase,
  cd.total_emp_dep,
  ib.ib_income_band_sk,
  td.t_shift,
  td.shift_cnt,
  ws.avg_tax_pct,
  RANK() OVER (PARTITION BY cd.cd_education_status ORDER BY cd.avg_purchase DESC) AS rank_within_edu
FROM cd_agg cd
JOIN ib_agg ib
  ON cd.avg_purchase BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
JOIN td_agg td
  ON (cd.demo_cnt % 24) = td.t_hour
JOIN ws_agg ws
  ON 1=1
WHERE cd.demo_cnt > 10
ORDER BY cd.avg_purchase DESC, ws.avg_tax_pct ASC
LIMIT 100
