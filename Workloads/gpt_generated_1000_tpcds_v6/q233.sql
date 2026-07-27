/*
Goal: Rank warehouses by total net profit from web sales, show inventory on‑hand metrics, classify profit as 'Profitable' or 'Loss', and provide row numbers per state ordered by quantity sold.
*/
WITH ws_agg AS (
    SELECT
        ws.ws_warehouse_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_list_price > 50
      AND ws.ws_ext_wholesale_cost < 3000
      AND ws.ws_sold_date_sk BETWEEN 2450800 AND 2451100
    GROUP BY ws.ws_warehouse_sk
),
inv_agg AS (
    SELECT
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand,
        COUNT(DISTINCT inv.inv_item_sk) AS distinct_items
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 0
      AND inv.inv_warehouse_sk IN (3, 12, 15, 18)
      AND inv.inv_date_sk >= 2450900
    GROUP BY inv.inv_warehouse_sk
)
SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    w.w_city,
    w.w_state,
    ws_agg.total_net_profit,
    ws_agg.total_quantity,
    ws_agg.profit_category,
    inv_agg.total_on_hand,
    inv_agg.distinct_items,
    RANK() OVER (ORDER BY ws_agg.total_net_profit DESC) AS profit_rank,
    ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY ws_agg.total_quantity DESC) AS qty_rownum
FROM warehouse w
JOIN ws_agg ON ws_agg.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN inv_agg ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_state IN ('CA', 'TX', 'NY')
  AND w.w_city LIKE '%Spring%'
  AND w.w_gmt_offset BETWEEN -5.00 AND 0.00
ORDER BY profit_rank
LIMIT 100
