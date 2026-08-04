WITH high_returns AS (
  SELECT
    cr.cr_returned_date_sk,
    d.d_date,
    cr.cr_call_center_sk,
    cc.cc_name,
    cr.cr_return_amount,
    td.t_time AS returned_hour,
    ROW_NUMBER() OVER (PARTITION BY cr.cr_returned_date_sk ORDER BY cr.cr_return_amount DESC) AS rn
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN LATERAL (
    SELECT t.t_time
    FROM time_dim t
    WHERE t.t_time_sk = cr.cr_returned_time_sk
  ) td ON true
  WHERE d.d_year = 2000
    AND cr.cr_return_amount > 100
),
filtered_high AS (
  SELECT
    cr_returned_date_sk,
    d_date,
    cr_call_center_sk,
    cc_name,
    cr_return_amount,
    returned_hour
  FROM high_returns
  WHERE rn <= 5
),
low_returns AS (
  SELECT
    cr.cr_returned_date_sk AS cr_returned_date_sk,
    d.d_date AS d_date,
    cr.cr_call_center_sk AS cr_call_center_sk,
    cc.cc_name AS cc_name,
    cr.cr_return_amount AS cr_return_amount,
    td.t_time AS returned_hour
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN LATERAL (
    SELECT t.t_time
    FROM time_dim t
    WHERE t.t_time_sk = cr.cr_returned_time_sk
  ) td ON true
  WHERE d.d_year = 2000
    AND cr.cr_return_amount <= 100
)
SELECT
  cr_returned_date_sk,
  d_date,
  cr_call_center_sk,
  cc_name,
  cr_return_amount,
  returned_hour
FROM filtered_high
EXCEPT
SELECT
  cr_returned_date_sk,
  d_date,
  cr_call_center_sk,
  cc_name,
  cr_return_amount,
  returned_hour
FROM low_returns
ORDER BY cr_returned_date_sk, cr_return_amount DESC
OFFSET 0 LIMIT 100
