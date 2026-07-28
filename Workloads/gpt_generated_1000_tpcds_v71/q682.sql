WITH avg_vals AS (
    SELECT avg(val) AS overall_avg_return
    FROM (
        SELECT cr_return_amount AS val FROM catalog_returns
        UNION ALL
        SELECT sr_return_amt AS val FROM store_returns
    ) AS combined
)
SELECT
    c.c_customer_id,
    sm.sm_type,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    CASE WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS loss_category,
    avg_vals.overall_avg_return
FROM catalog_returns cr
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
CROSS JOIN avg_vals
WHERE sm.sm_code = 'AIR'
  AND c.c_birth_day > 10
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr_ex
        WHERE sr_ex.sr_customer_sk = c.c_customer_sk
          AND sr_ex.sr_return_tax > 200
    )
GROUP BY c.c_customer_id, sm.sm_type, avg_vals.overall_avg_return

UNION ALL

SELECT
    c.c_customer_id,
    'STORE' AS sm_type,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    CASE WHEN SUM(sr.sr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS loss_category,
    avg_vals.overall_avg_return
FROM store_returns sr
JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
CROSS JOIN avg_vals
WHERE sr.sr_return_tax BETWEEN 10 AND 100
  AND c.c_salutation = 'Sir'
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr_ex
        WHERE cr_ex.cr_refunded_customer_sk = c.c_customer_sk
          AND cr_ex.cr_return_tax > 150
    )
GROUP BY c.c_customer_id, avg_vals.overall_avg_return

ORDER BY loss_category, total_return_amount DESC
LIMIT 100
