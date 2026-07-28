WITH filtered_sales AS (
    SELECT 
        ws.ws_warehouse_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        w.w_warehouse_name,
        w.w_state,
        w.w_gmt_offset
    FROM web_sales ws
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_warehouse_sk IN (9, 13, 19)
      AND w.w_gmt_offset = -5.00
      AND w.w_warehouse_name LIKE '%central%'
      AND ws.ws_ship_cdemo_sk = 1849009
      AND ws.ws_ship_hdemo_sk = 1587
      AND ws.ws_item_sk = 68256
      AND ws.ws_quantity BETWEEN 1 AND 10
      AND ws.ws_net_profit > -100.00
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_item_sk = ws.ws_item_sk
            AND ws2.ws_quantity > 5
            AND ws2.ws_warehouse_sk = ws.ws_warehouse_sk
      )
)
SELECT
    w_warehouse_name,
    w_state,
    CASE
        WHEN SUM(ws_net_profit) > 0 THEN 'overall profit'
        ELSE 'overall loss'
    END AS profit_category,
    COUNT(*) AS order_count,
    SUM(ws_net_paid) AS total_net_paid,
    AVG(ws_quantity) AS avg_quantity,
    MIN(ws_net_paid) AS min_net_paid,
    MAX(ws_net_paid) AS max_net_paid
FROM filtered_sales
GROUP BY w_warehouse_name, w_state
HAVING SUM(ws_net_paid) > 1000
   AND COUNT(*) >= 10
ORDER BY total_net_paid DESC
LIMIT 100
