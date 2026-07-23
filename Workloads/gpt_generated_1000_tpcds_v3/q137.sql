WITH filtered AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_reason_sk,
        cr.cr_ship_mode_sk,
        r.r_reason_desc,
        sm.sm_carrier,
        sm.sm_type,
        sm.sm_code
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)price|damage|exchange')
      AND sm.sm_code LIKE 'A%'
)
SELECT
    f.r_reason_desc,
    regexp_extract(f.r_reason_desc, '(price|damage|exchange)', 1) AS matched_keyword,
    f.sm_carrier,
    f.sm_type,
    COUNT(DISTINCT f.cr_order_number) AS distinct_orders,
    SUM(f.cr_return_amount) AS total_return_amount,
    AVG(f.cr_net_loss) AS avg_net_loss,
    CONCAT(f.sm_carrier, ' - ', f.sm_type) AS carrier_type,
    (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2) AS overall_avg_return_amount
FROM filtered f
GROUP BY
    f.r_reason_desc,
    regexp_extract(f.r_reason_desc, '(price|damage|exchange)', 1),
    f.sm_carrier,
    f.sm_type
HAVING SUM(f.cr_return_amount) > 1000
ORDER BY total_return_amount DESC
LIMIT 10
