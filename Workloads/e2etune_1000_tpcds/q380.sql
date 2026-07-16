WITH cd_filtered AS (
  SELECT *
  FROM customer_demographics
  WHERE cd_credit_rating IN ('Good', 'Low Risk', 'High Risk')
    AND cd_marital_status IN ('M', 'S')
),
ws_filtered AS (
  SELECT *
  FROM web_site
  WHERE web_country = 'United States'
    AND web_open_date_sk BETWEEN 20000101 AND 20221231
    AND web_gmt_offset > -5
),
base_agg AS (
  SELECT
    ws.web_state,
    cd.cd_credit_rating,
    cd.cd_marital_status,
    COUNT(*) AS pair_count,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(cd.cd_dep_count) AS total_dependents,
    AVG(cd.cd_dep_count) AS avg_dependents_per_customer,
    AVG(cd.cd_purchase_estimate) / NULLIF(AVG(cd.cd_dep_count), 0) AS purchase_per_dependent
  FROM cd_filtered cd
  JOIN ws_filtered ws
    ON 1 = 1
  GROUP BY ws.web_state, cd.cd_credit_rating, cd.cd_marital_status
  HAVING COUNT(*) > 100
)
SELECT
  web_state,
  cd_credit_rating,
  cd_marital_status,
  pair_count,
  avg_purchase_estimate,
  total_dependents,
  avg_dependents_per_customer,
  purchase_per_dependent,
  RANK() OVER (PARTITION BY web_state ORDER BY avg_purchase_estimate DESC) AS credit_rating_rank_in_state
FROM base_agg
ORDER BY web_state ASC, credit_rating_rank_in_state ASC
LIMIT 100
