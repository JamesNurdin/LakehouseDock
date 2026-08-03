WITH sales_metrics AS (
    SELECT
        cc.cc_name AS call_center_name,
        sm.sm_type AS ship_mode_type,
        'Profit' AS metric_type,
        cs.cs_net_paid_inc_tax AS metric_value,
        CASE WHEN cs.cs_net_paid_inc_tax >= 1000 THEN 'High' ELSE 'Medium' END AS profit_bracket,
        ARRAY[cs.cs_net_paid_inc_tax, cs.cs_net_paid_inc_tax * 0.1] AS metric_array
    FROM catalog_sales AS cs
    JOIN call_center   AS cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode     AS sm ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    WHERE cs.cs_net_paid_inc_tax IS NOT NULL
),
sales_unnested AS (
    SELECT
        sm.call_center_name,
        sm.ship_mode_type,
        sm.metric_type,
        sm.metric_value,
        sm.profit_bracket,
        e AS metric_detail,
        lc.size_category
    FROM sales_metrics AS sm
    CROSS JOIN UNNEST(sm.metric_array) AS t(e)
    CROSS JOIN LATERAL (
        SELECT CASE WHEN e > 1000 THEN 'Big' ELSE 'Small' END AS size_category
    ) AS lc
),
returns_metrics AS (
    SELECT
        cc.cc_name AS call_center_name,
        sm.sm_type AS ship_mode_type,
        'Return' AS metric_type,
        cr.cr_return_amount AS metric_value,
        CASE WHEN cr.cr_return_amount >= 500 THEN 'High' ELSE 'Medium' END AS profit_bracket,
        ARRAY[cr.cr_return_amount, cr.cr_return_amount * 0.2] AS metric_array
    FROM catalog_returns AS cr
    JOIN call_center   AS cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode     AS sm ON cr.cr_ship_mode_sk   = sm.sm_ship_mode_sk
    WHERE cr.cr_return_amount IS NOT NULL
),
returns_unnested AS (
    SELECT
        rm.call_center_name,
        rm.ship_mode_type,
        rm.metric_type,
        rm.metric_value,
        rm.profit_bracket,
        e AS metric_detail,
        lc.size_category
    FROM returns_metrics AS rm
    CROSS JOIN UNNEST(rm.metric_array) AS t(e)
    CROSS JOIN LATERAL (
        SELECT CASE WHEN e > 500 THEN 'Big' ELSE 'Small' END AS size_category
    ) AS lc
)
SELECT
    call_center_name,
    ship_mode_type,
    metric_type,
    metric_value,
    profit_bracket,
    metric_detail,
    size_category
FROM (
    SELECT * FROM sales_unnested
    UNION ALL
    SELECT * FROM returns_unnested
) AS combined
ORDER BY call_center_name, ship_mode_type, metric_type DESC
LIMIT 100
