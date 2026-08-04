WITH base AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_fee,
        sm.sm_type,
        sm.sm_carrier,
        map(
            ARRAY['return_amount', 'fee'],
            ARRAY[cr.cr_return_amount, cr.cr_fee]
        ) AS kv_map
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_return_amount > 1000
      AND sm.sm_type IN ('OVERNI...','REGULAR')
),
expanded AS (
    SELECT
        b.cr_order_number,
        b.cr_return_amount,
        b.cr_fee,
        b.sm_type,
        b.sm_carrier,
        kv.key   AS metric,
        kv.value AS metric_value
    FROM base b
    CROSS JOIN UNNEST(b.kv_map) AS kv(key, value)
),
full_joined AS (
    SELECT
        e.cr_order_number,
        e.metric,
        e.metric_value,
        e.sm_type,
        e.sm_carrier
    FROM expanded e
    FULL OUTER JOIN (
        SELECT
            cr_return_amount AS ra,
            cr_fee          AS f
        FROM catalog_returns
        WHERE cr_return_amount < 200
    ) low
        ON e.metric_value = low.ra
)
SELECT
    fj.cr_order_number,
    fj.metric,
    fj.metric_value,
    fj.sm_type,
    fj.sm_carrier
FROM full_joined fj
WHERE fj.metric = 'return_amount'

UNION ALL

SELECT
    fj.cr_order_number,
    fj.metric,
    fj.metric_value,
    fj.sm_type,
    fj.sm_carrier
FROM full_joined fj
WHERE fj.metric = 'fee'

EXCEPT

SELECT
    fj.cr_order_number,
    fj.metric,
    fj.metric_value,
    fj.sm_type,
    fj.sm_carrier
FROM full_joined fj
WHERE fj.metric_value < 1500

ORDER BY cr_order_number DESC
LIMIT 100
