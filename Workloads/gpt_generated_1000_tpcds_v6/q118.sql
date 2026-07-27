WITH refunded AS (
  SELECT
    w.w_warehouse_name AS w_warehouse_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  WHERE cd.cd_gender = 'M'
    AND w.w_state = 'CA'
    AND t.t_hour BETWEEN 9 AND 17
    AND cr.cr_fee > 20
  GROUP BY w.w_warehouse_name
),
returning AS (
  SELECT
    w.w_warehouse_name AS w_warehouse_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
  JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
  WHERE cd.cd_gender = 'F'
    AND w.w_state = 'NY'
    AND t.t_hour BETWEEN 9 AND 17
    AND cr.cr_fee > 20
  GROUP BY w.w_warehouse_name
)
SELECT
  w_warehouse_name,
  total_return_amount,
  return_cnt
FROM refunded
UNION ALL
SELECT
  w_warehouse_name,
  total_return_amount,
  return_cnt
FROM returning
ORDER BY total_return_amount DESC
LIMIT 100
