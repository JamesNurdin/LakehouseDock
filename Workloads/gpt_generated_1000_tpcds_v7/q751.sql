WITH cc_returns AS (
    SELECT
        'Call Center' AS entity_type,
        cc.cc_name AS entity_name,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year = 2000
    GROUP BY cc.cc_name
),
sm_returns AS (
    SELECT
        'Ship Mode' AS entity_type,
        sm.sm_type AS entity_name,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2000
    GROUP BY sm.sm_type
)
SELECT entity_type, entity_name, total_return_amount FROM cc_returns
UNION ALL
SELECT entity_type, entity_name, total_return_amount FROM sm_returns
LIMIT 100
