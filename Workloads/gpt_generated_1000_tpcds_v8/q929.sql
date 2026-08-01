WITH base AS (
    SELECT
        cr.cr_ship_mode_sk,
        cr.cr_return_tax,
        cr.cr_store_credit,
        cr.cr_refunded_cash,
        cr.cr_return_amount,
        sm.sm_carrier,
        sm.sm_contract
    FROM catalog_returns cr
    INNER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_return_tax > 20
      AND cr.cr_store_credit BETWEEN 0 AND 500
      AND sm.sm_carrier = 'FEDEX'
      AND sm.sm_contract LIKE 'I3uCel%'
      AND cr.cr_refunded_cash < 3000
),
full_join AS (
    SELECT
        cr.cr_ship_mode_sk,
        cr.cr_return_amount,
        sm.sm_carrier,
        sm.sm_contract
    FROM catalog_returns cr
    FULL OUTER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE (cr.cr_return_amount IS NOT NULL AND cr.cr_return_amount > 50)
       OR (sm.sm_carrier IS NOT NULL AND sm.sm_carrier = 'BOXBUNDLES')
),
right_join AS (
    SELECT
        cr.cr_ship_mode_sk,
        cr.cr_return_quantity,
        sm.sm_type
    FROM catalog_returns cr
    RIGHT OUTER JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_type IS NOT NULL
),
anti AS (
    SELECT cr.cr_ship_mode_sk
    FROM catalog_returns cr
    WHERE NOT EXISTS (
        SELECT 1
        FROM ship_mode sm
        WHERE sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
          AND sm.sm_carrier = 'MSC'
    )
),
-- LATERAL sub‑query to fetch the maximum refunded cash per ship mode
lateral_cte AS (
    SELECT
        cr.cr_ship_mode_sk,
        cr.cr_return_amount,
        lt.max_refund
    FROM catalog_returns cr
    LEFT JOIN LATERAL (
        SELECT MAX(cr2.cr_refunded_cash) AS max_refund
        FROM catalog_returns cr2
        WHERE cr2.cr_ship_mode_sk = cr.cr_ship_mode_sk
          AND cr2.cr_refunded_cash > 100
    ) lt ON TRUE
),
union_all AS (
    SELECT cr_ship_mode_sk, cr_return_amount, sm_carrier, sm_contract
    FROM base
    UNION
    SELECT cr_ship_mode_sk, cr_return_amount, sm_carrier, sm_contract
    FROM full_join
),
final AS (
    SELECT
        u.cr_ship_mode_sk,
        SUM(u.cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns,
        AVG(CASE WHEN u.sm_carrier = 'FEDEX' THEN u.cr_return_amount END) AS avg_fedex_return,
        MIN(u.cr_return_amount) AS min_return,
        MAX(u.cr_return_amount) AS max_return
    FROM union_all u
    WHERE u.cr_ship_mode_sk NOT IN (SELECT cr_ship_mode_sk FROM anti)
    GROUP BY u.cr_ship_mode_sk
    HAVING COUNT(*) > 1
)
SELECT
    f.cr_ship_mode_sk,
    f.total_return_amount,
    f.cnt_returns,
    f.avg_fedex_return,
    f.min_return,
    f.max_return,
    (
        SELECT COUNT(*)
        FROM right_join r
        WHERE r.cr_ship_mode_sk = f.cr_ship_mode_sk
    ) AS right_join_match_cnt,
    (
        SELECT lt.max_refund
        FROM lateral_cte lt
        WHERE lt.cr_ship_mode_sk = f.cr_ship_mode_sk
    ) AS max_refunded_cash
FROM final f
ORDER BY f.total_return_amount DESC
OFFSET 0
LIMIT 100
