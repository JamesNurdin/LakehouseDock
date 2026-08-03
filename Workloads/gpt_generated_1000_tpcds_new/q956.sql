WITH sampled_returns AS (
    SELECT
        cr_return_amount,
        cr_return_quantity,
        cr_order_number,
        cr_ship_mode_sk
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
),
sampled_ship AS (
    SELECT
        sm_ship_mode_sk,
        sm_type,
        sm_code
    FROM ship_mode
    TABLESAMPLE BERNOULLI (100)
)
SELECT
    sm.sm_ship_mode_sk,
    sm.sm_type,
    sm.sm_code,
    concat(sm.sm_type, ' ', sm.sm_code) AS mode_full,
    regexp_extract(sm.sm_code, '([A-Z]+)', 1) AS code_alpha,
    CASE
        WHEN sm.sm_type IS NOT NULL AND regexp_like(sm.sm_type, '^OVER') THEN 'Overnight'
        WHEN sm.sm_type IS NOT NULL AND sm.sm_type LIKE '%DAY%' THEN 'Daytime'
        ELSE 'Other'
    END AS type_category,
    COUNT(cr.cr_order_number) AS returned_orders,
    COALESCE(SUM(cr.cr_return_amount), 0) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity
FROM sampled_returns cr
FULL OUTER JOIN sampled_ship sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
    (sm.sm_type IS NOT NULL AND (regexp_like(sm.sm_type, 'DAY') OR sm.sm_type LIKE '%DAY%'))
    OR cr.cr_return_amount > 0
GROUP BY
    sm.sm_ship_mode_sk,
    sm.sm_type,
    sm.sm_code,
    concat(sm.sm_type, ' ', sm.sm_code),
    regexp_extract(sm.sm_code, '([A-Z]+)', 1),
    CASE
        WHEN sm.sm_type IS NOT NULL AND regexp_like(sm.sm_type, '^OVER') THEN 'Overnight'
        WHEN sm.sm_type IS NOT NULL AND sm.sm_type LIKE '%DAY%' THEN 'Daytime'
        ELSE 'Other'
    END
ORDER BY
    total_return_amount DESC
LIMIT 100
