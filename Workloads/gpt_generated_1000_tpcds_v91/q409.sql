WITH sales_agg AS (
    SELECT
        cc.cc_name,
        sm.sm_code,
        CASE idx WHEN 1 THEN 'ext_sales_price' WHEN 2 THEN 'ext_discount_amt' END AS metric_type,
        metric_value
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    CROSS JOIN UNNEST(ARRAY[cs.cs_ext_sales_price, cs.cs_ext_discount_amt]) WITH ORDINALITY AS t(metric_value, idx)
    WHERE cc.cc_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND sm.sm_code = 'AIR'
      AND EXISTS (
            SELECT 1 FROM promotion p
            WHERE p.p_promo_sk = cs.cs_promo_sk
              AND p.p_channel_event = 'N'
        )
),
sales_grouped AS (
    SELECT
        cc_name,
        sm_code,
        metric_type,
        SUM(metric_value) AS total_amount
    FROM sales_agg
    GROUP BY cc_name, sm_code, metric_type
    HAVING SUM(metric_value) > 1000
),
returns_agg AS (
    SELECT
        cc.cc_name,
        sm.sm_code,
        CASE idx WHEN 1 THEN 'return_amount' WHEN 2 THEN 'return_tax' END AS metric_type,
        metric_value
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    CROSS JOIN UNNEST(ARRAY[cr.cr_return_amount, cr.cr_return_tax]) WITH ORDINALITY AS t(metric_value, idx)
    WHERE sm.sm_code = 'AIR'
      AND EXISTS (
            SELECT 1 FROM reason r
            WHERE r.r_reason_sk = cr.cr_reason_sk
              AND r.r_reason_desc LIKE '%defective%'
        )
),
returns_grouped AS (
    SELECT
        cc_name,
        sm_code,
        metric_type,
        SUM(metric_value) AS total_amount
    FROM returns_agg
    GROUP BY cc_name, sm_code, metric_type
    HAVING SUM(metric_value) > 500
)
SELECT DISTINCT
    cc_name,
    sm_code,
    metric_type,
    total_amount
FROM (
    SELECT cc_name, sm_code, metric_type, total_amount FROM sales_grouped
    UNION ALL
    SELECT cc_name, sm_code, metric_type, total_amount FROM returns_grouped
) u
ORDER BY total_amount DESC, cc_name
LIMIT 100
