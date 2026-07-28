WITH sales_cte AS (
    SELECT
        i.i_category AS category,
        cc.cc_market_manager AS market_manager,
        SUM(cs.cs_ext_sales_price) AS amount,
        SUM(cs.cs_quantity) AS quantity,
        CASE WHEN SUM(cs.cs_ext_sales_price) > 100000 THEN 'High' ELSE 'Medium' END AS level,
        'Sales' AS metric_type
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_market_manager = 'James Mcdonald'
    GROUP BY i.i_category, cc.cc_market_manager
),
returns_cte AS (
    SELECT
        i.i_category AS category,
        cc.cc_market_manager AS market_manager,
        SUM(cr.cr_return_amount) AS amount,
        SUM(cr.cr_return_quantity) AS quantity,
        CASE WHEN SUM(cr.cr_return_amount) > 50000 THEN 'High' ELSE 'Medium' END AS level,
        'Returns' AS metric_type
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE sm.sm_carrier = 'DHL'
    GROUP BY i.i_category, cc.cc_market_manager
)
SELECT
    category,
    market_manager,
    metric_type,
    amount,
    quantity,
    level
FROM sales_cte
UNION ALL
SELECT
    category,
    market_manager,
    metric_type,
    amount,
    quantity,
    level
FROM returns_cte
ORDER BY category, metric_type
LIMIT 100
