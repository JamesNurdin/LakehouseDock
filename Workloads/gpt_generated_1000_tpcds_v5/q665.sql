WITH inv_metrics AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS description,
        'inventory_qty' AS metric_type,
        SUM(inv.inv_quantity_on_hand) AS metric_value
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE inv.inv_warehouse_sk = 12
      AND inv.inv_date_sk > 2450900
    GROUP BY i.i_item_id, i.i_item_desc
),
profit_metrics AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS description,
        'net_profit' AS metric_type,
        SUM(ws.ws_net_profit) AS metric_value
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_warehouse_sk = 12
      AND ws.ws_sold_date_sk BETWEEN 2450900 AND 2451000
    GROUP BY i.i_item_id, i.i_item_desc
)
SELECT
    item_id,
    description,
    metric_type,
    metric_value
FROM inv_metrics
UNION ALL
SELECT
    item_id,
    description,
    metric_type,
    metric_value
FROM profit_metrics
ORDER BY metric_value DESC
LIMIT 100
