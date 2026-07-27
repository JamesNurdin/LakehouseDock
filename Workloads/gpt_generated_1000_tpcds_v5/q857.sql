WITH refunded AS (
  SELECT DISTINCT
    cc.cc_call_center_id,
    cc.cc_name,
    cust.c_customer_id,
    SUM(cr.cr_return_amount) AS total_refund_amount
  FROM catalog_returns cr
  JOIN customer cust
    ON cr.cr_refunded_customer_sk = cust.c_customer_sk
  JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  WHERE cc.cc_division = 1
    AND cust.c_birth_day > 20
  GROUP BY cc.cc_call_center_id, cc.cc_name, cust.c_customer_id
),
returning AS (
  SELECT DISTINCT
    cc.cc_call_center_id,
    cc.cc_name,
    cust.c_customer_id,
    SUM(cr.cr_return_amount) AS total_return_amount
  FROM catalog_returns cr
  JOIN customer cust
    ON cr.cr_returning_customer_sk = cust.c_customer_sk
  JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  WHERE cc.cc_company_name LIKE 'pri%'
    AND cr.cr_returned_time_sk BETWEEN 60000 AND 80000
  GROUP BY cc.cc_call_center_id, cc.cc_name, cust.c_customer_id
)
SELECT
  call_center_id,
  cc_name,
  customer_id,
  total_amount,
  customer_role
FROM (
  SELECT
    cc_call_center_id AS call_center_id,
    cc_name,
    c_customer_id AS customer_id,
    total_refund_amount AS total_amount,
    'refunded' AS customer_role
  FROM refunded
  UNION ALL
  SELECT
    cc_call_center_id AS call_center_id,
    cc_name,
    c_customer_id AS customer_id,
    total_return_amount AS total_amount,
    'returning' AS customer_role
  FROM returning
) combined
ORDER BY total_amount DESC
LIMIT 100
