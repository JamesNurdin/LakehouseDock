SELECT
    cr.cr_returning_customer_sk,
    sm.sm_type,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_store_credit) AS total_store_credit
FROM catalog_returns cr
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_type = 'OVERNIGHT'
  AND cr.cr_return_amount > 50
GROUP BY cr.cr_returning_customer_sk, sm.sm_type
ORDER BY total_return_amount DESC
LIMIT 100
