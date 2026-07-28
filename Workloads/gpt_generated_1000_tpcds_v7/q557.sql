WITH cr_join AS (
        SELECT cr.cr_returned_date_sk,
               cr.cr_return_amount,
               cr.cr_return_quantity,
               cr.cr_warehouse_sk,
               cr.cr_ship_mode_sk,
               cr.cr_catalog_page_sk,
               cr.cr_order_number
        FROM catalog_returns cr
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE cp.cp_start_date_sk = 2451055
          AND cp.cp_catalog_page_number = 13
          AND sm.sm_contract = 'O9V6oF8RJnLMmZYd1   '
    ),
    inv_join AS (
        SELECT i.inv_warehouse_sk,
               i.inv_quantity_on_hand,
               i.inv_date_sk
        FROM inventory i
        JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
        WHERE i.inv_quantity_on_hand > 500
          AND i.inv_date_sk = 2451053
    ),
    ws_join AS (
        SELECT ws.ws_order_number,
               ws.ws_item_sk,
               ws.ws_sold_date_sk,
               ws.ws_quantity,
               ws.ws_net_profit,
               ws.ws_ship_mode_sk,
               ws.ws_warehouse_sk,
               ws.ws_sales_price
        FROM web_sales ws
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        WHERE ws.ws_sold_date_sk = 2451115
          AND ws.ws_quantity BETWEEN 2 AND 5
          AND sm.sm_type = 'AIR'
    ),
    wr_join AS (
        SELECT wr.wr_order_number,
               wr.wr_return_amt,
               wr.wr_return_quantity
        FROM web_returns wr
        JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_item_sk = ws.ws_item_sk
        WHERE wr.wr_return_quantity > 1
    )
SELECT w.w_warehouse_name,
       sm.sm_ship_mode_id,
       cp.cp_department,
       SUM(ws.ws_net_profit) AS total_net_profit,
       COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
       AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
       SUM(cr.cr_return_amount) AS total_catalog_return_amount,
       SUM(wr.wr_return_amt) AS total_web_return_amount,
       MIN(ws.ws_sold_date_sk) AS earliest_sale_date_sk,
       MAX(ws.ws_sold_date_sk) AS latest_sale_date_sk
FROM web_sales ws
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_returns cr ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
                              AND cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                           AND wr.wr_item_sk = ws.ws_item_sk
WHERE w.w_state = 'CA'
  AND sm.sm_contract = 'Xjy3ZPuiDjzHlRx14Z3 '
  AND cp.cp_end_date_sk = 2451453
  AND inv.inv_quantity_on_hand < 800
  AND cr.cr_return_quantity > 0
  AND wr.wr_return_amt > 0
GROUP BY w.w_warehouse_name, sm.sm_ship_mode_id, cp.cp_department
ORDER BY total_net_profit DESC
LIMIT 20
