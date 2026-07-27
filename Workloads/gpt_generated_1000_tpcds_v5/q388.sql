WITH refunded_addr AS (
    SELECT ca_address_sk, ca_state
    FROM customer_address
    WHERE ca_state = 'CA'
),
returning_addr AS (
    SELECT ca_address_sk, ca_state
    FROM customer_address
    WHERE ca_state = 'NY'
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    'refunded' AS return_type
FROM catalog_returns cr
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN refunded_addr ra
  ON cr.cr_refunded_addr_sk = ra.ca_address_sk
WHERE cc.cc_hours = '8AM-4PM'
  AND cr.cr_return_amount > 100
GROUP BY cc.cc_call_center_id, cc.cc_name

UNION ALL

SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    'returning' AS return_type
FROM catalog_returns cr
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN returning_addr ra
  ON cr.cr_returning_addr_sk = ra.ca_address_sk
WHERE cc.cc_hours = '8AM-12AM'
  AND cr.cr_return_amount > 150
GROUP BY cc.cc_call_center_id, cc.cc_name
