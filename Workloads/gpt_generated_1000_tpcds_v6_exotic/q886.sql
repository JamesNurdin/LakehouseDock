WITH return_data AS (
    SELECT
        i.i_item_id AS item_id,
        SUM(cr.cr_return_amount) AS total_return_amount,
        (
            SELECT i2.i_current_price
            FROM item i2
            WHERE i2.i_item_sk = cr.cr_item_sk
        ) AS current_price,
        'RETURN' AS source
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Damaged'
      AND w.w_zip = '78370'
    GROUP BY i.i_item_id, cr.cr_item_sk
),

sales_data AS (
    SELECT
        i.i_item_id AS item_id,
        SUM(ws.ws_net_paid) AS total_sales_net,
        (
            SELECT i2.i_current_price
            FROM item i2
            WHERE i2.i_item_sk = ws.ws_item_sk
        ) AS current_price,
        'SALES' AS source
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_zip = '78370'
    GROUP BY i.i_item_id, ws.ws_item_sk
)
SELECT
    item_id,
    source,
    total_return_amount,
    total_sales_net,
    current_price
FROM (
    SELECT item_id, source, total_return_amount, NULL AS total_sales_net, current_price
    FROM return_data
    UNION ALL
    SELECT item_id, source, NULL AS total_return_amount, total_sales_net, current_price
    FROM sales_data
) t
ORDER BY item_id, source
