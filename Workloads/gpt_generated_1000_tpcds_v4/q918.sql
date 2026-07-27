WITH filtered_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_item_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_return_ship_cost,
        cr.cr_fee,
        cr.cr_store_credit,
        cr.cr_ship_mode_sk
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 200
      AND cr.cr_return_tax BETWEEN 5 AND 30
      AND cr.cr_store_credit > 50
      AND cr.cr_return_quantity >= 1
)
SELECT
    sm.sm_carrier,
    sm.sm_contract,
    sm.sm_type,
    COUNT(*) AS return_cnt,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_tax) AS avg_return_tax,
    MIN(fr.cr_return_ship_cost) AS min_ship_cost,
    MAX(fr.cr_fee) AS max_fee
FROM filtered_returns fr
JOIN ship_mode sm
    ON fr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE sm.sm_carrier = 'DHL'
  AND sm.sm_contract LIKE 'Xjy3ZPui%'
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = fr.cr_refunded_customer_sk
          AND cr2.cr_return_amount > 1000
    )
GROUP BY sm.sm_carrier, sm.sm_contract, sm.sm_type
ORDER BY total_return_amount DESC
LIMIT 100
