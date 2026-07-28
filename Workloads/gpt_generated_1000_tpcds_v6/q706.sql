WITH catalog_ret AS (
    SELECT
        'catalog_return' AS source,
        i.i_item_id,
        i.i_product_name,
        sm.sm_type AS ship_mode_type,
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS total_amount
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_amount > 0
      AND r.r_reason_desc LIKE '%damaged%'
    GROUP BY i.i_item_id, i.i_product_name, sm.sm_type, r.r_reason_desc
),
web_sales_agg AS (
    SELECT
        'web_sales' AS source,
        i.i_item_id,
        i.i_product_name,
        sm.sm_type AS ship_mode_type,
        NULL AS r_reason_desc,
        SUM(ws.ws_net_paid) AS total_amount
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_net_paid > 0
      AND sm.sm_type LIKE 'AIR%'
    GROUP BY i.i_item_id, i.i_product_name, sm.sm_type
)
SELECT
    source,
    i_item_id,
    i_product_name,
    ship_mode_type,
    r_reason_desc,
    total_amount
FROM catalog_ret
UNION ALL
SELECT
    source,
    i_item_id,
    i_product_name,
    ship_mode_type,
    r_reason_desc,
    total_amount
FROM web_sales_agg
ORDER BY total_amount DESC
LIMIT 100
