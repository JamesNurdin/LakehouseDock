WITH web_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
    GROUP BY i.i_item_sk, i.i_item_id
),
store_returns_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        SUM(sr.sr_return_quantity) AS total_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
    GROUP BY i.i_item_sk, i.i_item_id
),
inventory_on_date AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_date = DATE '2022-12-31'
    GROUP BY i.i_item_sk, i.i_item_id
),
common_items AS (
    SELECT ws_i.i_item_sk, ws_i.i_item_id
    FROM web_sales_agg ws_i
    UNION
    SELECT sr_i.i_item_sk, sr_i.i_item_id
    FROM store_returns_agg sr_i
    INTERSECT
    SELECT inv_i.i_item_sk, inv_i.i_item_id
    FROM inventory_on_date inv_i
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    ws_ag.total_quantity AS web_quantity,
    sr_ag.total_quantity AS return_quantity,
    inv_ag.total_quantity AS inventory_quantity,
    la.total_activity,
    CASE
        WHEN la.total_activity > 500 THEN 'High'
        ELSE 'Low'
    END AS demand_category
FROM common_items ci
JOIN item i ON ci.i_item_sk = i.i_item_sk
LEFT JOIN web_sales_agg ws_ag ON ci.i_item_sk = ws_ag.i_item_sk
LEFT JOIN store_returns_agg sr_ag ON ci.i_item_sk = sr_ag.i_item_sk
LEFT JOIN inventory_on_date inv_ag ON ci.i_item_sk = inv_ag.i_item_sk
CROSS JOIN LATERAL (
    SELECT COALESCE(ws_ag.total_quantity, 0) + COALESCE(sr_ag.total_quantity, 0) AS total_activity
) AS la
ORDER BY la.total_activity DESC
OFFSET 0
LIMIT 100
