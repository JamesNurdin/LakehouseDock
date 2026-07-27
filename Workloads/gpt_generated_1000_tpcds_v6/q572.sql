WITH sr_agg AS (
    SELECT
        sr_item_sk,
        COUNT(*) AS cnt_returns,
        SUM(sr_return_amt) AS total_return_amt,
        AVG(sr_return_tax) AS avg_return_tax
    FROM store_returns
    WHERE sr_return_ship_cost > 50
    GROUP BY sr_item_sk
),
ws_agg AS (
    SELECT
        ws_item_sk,
        ws_ship_mode_sk,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS cnt_orders
    FROM web_sales
    WHERE ws_quantity > 5
    GROUP BY ws_item_sk, ws_ship_mode_sk
)
SELECT
    sm.sm_code,
    inv.inv_warehouse_sk,
    i.i_item_id,
    sr.cnt_returns,
    sr.total_return_amt,
    ws.total_net_paid,
    ws.total_quantity,
    ws.cnt_orders,
    ROW_NUMBER() OVER (PARTITION BY sm.sm_code ORDER BY ws.total_net_paid DESC) AS revenue_rank
FROM inventory inv
JOIN item i ON inv.inv_item_sk = i.i_item_sk
JOIN ws_agg ws ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
JOIN sr_agg sr ON sr.sr_item_sk = i.i_item_sk
WHERE inv.inv_warehouse_sk = 2
  AND sm.sm_code = 'AIR'
  AND i.i_brand_id = 123
  AND i.i_item_sk IN (SELECT sr_item_sk FROM store_returns WHERE sr_reversed_charge > 100)
LIMIT 100
