WITH sampled_returns AS (
  SELECT *
  FROM catalog_returns TABLESAMPLE BERNOULLI (10)
),
filtered_returns AS (
  SELECT 
    cr_returned_date_sk,
    cr_returned_time_sk,
    cr_return_quantity,
    cr_return_amount,
    cr_reason_sk,
    cr_catalog_page_sk,
    cr_ship_mode_sk,
    cr_refunded_customer_sk
  FROM sampled_returns
  WHERE regexp_like(CAST(cr_return_amount AS varchar), '^\\d+\\.\\d{2}$')
    AND cr_return_quantity > 0
),
reason_desc AS (
  SELECT r_reason_sk, r_reason_desc
  FROM reason
  WHERE r_reason_desc LIKE '%purchase%'
),
joined_returns AS (
  SELECT 
    fr.cr_returned_date_sk,
    dd.d_year,
    fr.cr_return_amount,
    rd.r_reason_desc,
    cp.cp_catalog_number,
    sm.sm_type
  FROM filtered_returns fr
  JOIN date_dim dd ON fr.cr_returned_date_sk = dd.d_date_sk
  JOIN reason rd ON fr.cr_reason_sk = rd.r_reason_sk
  JOIN catalog_page cp ON fr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON fr.cr_ship_mode_sk = sm.sm_ship_mode_sk
),
union_set AS (
  SELECT DISTINCT d_year, cp_catalog_number, r_reason_desc
  FROM joined_returns
  WHERE cp_catalog_number BETWEEN 1 AND 20
  UNION
  SELECT DISTINCT d_year, cp_catalog_number, r_reason_desc
  FROM joined_returns
  WHERE r_reason_desc LIKE '%gift%'
),
except_set AS (
  SELECT d_year, cp_catalog_number
  FROM union_set
  EXCEPT
  SELECT d_year, cp_catalog_number
  FROM joined_returns
  WHERE r_reason_desc LIKE '%duplicate%'
),
cu AS (
  SELECT 
    dd.d_year,
    cp.cp_catalog_number,
    rd.r_reason_desc,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound
  FROM date_dim dd
  JOIN catalog_page cp ON cp.cp_start_date_sk = dd.d_date_sk
  JOIN reason rd ON rd.r_reason_sk = 10
  JOIN household_demographics hd ON 1 = 1
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE rd.r_reason_desc LIKE '%lost%'
),
full_outer AS (
  SELECT 
    es.d_year,
    es.cp_catalog_number,
    cu.r_reason_desc,
    cu.hd_income_band_sk,
    cu.ib_lower_bound,
    cu.ib_upper_bound
  FROM except_set es
  FULL OUTER JOIN cu ON es.d_year = cu.d_year AND es.cp_catalog_number = cu.cp_catalog_number
)
SELECT
  CONCAT('Year ', CAST(d_year AS varchar), ': ', CAST(cp_catalog_number AS varchar)) AS year_catalog,
  r_reason_desc,
  hd_income_band_sk,
  ib_lower_bound,
  ib_upper_bound,
  (SELECT max(ib_upper_bound) FROM income_band) AS max_income_upper
FROM full_outer
WHERE hd_income_band_sk IS NOT NULL OR r_reason_desc IS NOT NULL
ORDER BY year_catalog
LIMIT 100
