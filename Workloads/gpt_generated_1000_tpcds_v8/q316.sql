WITH
  warehouse_filtered AS (
    SELECT *
    FROM warehouse
    WHERE w_street_name = 'Oak Ninth'
      AND w_suite_number = 'Suite 480'
      AND w_state = 'CA'
  ),
  item_set AS (
    SELECT inv_item_sk AS item_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    INTERSECT
    SELECT ws_item_sk AS item_sk
    FROM web_sales
    WHERE ws_quantity > 0
  )
SELECT
  w.w_warehouse_id,
  w.w_city,
  COUNT(DISTINCT ws.ws_order_number)        AS orders_cnt,
  SUM(ws.ws_ext_sales_price)                AS total_sales,
  AVG(ws.ws_net_profit)                     AS avg_profit,
  MIN(ws.ws_ext_sales_price)                AS min_sale,
  MAX(ws.ws_ext_sales_price)                AS max_sale
FROM warehouse_filtered w
JOIN web_sales ws
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN inventory i
  ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE ws.ws_sold_date_sk = 2451011
  AND ws.ws_quantity > 5
  AND ws.ws_net_profit > 0
  AND i.inv_quantity_on_hand > (
        SELECT AVG(inv_quantity_on_hand)
        FROM inventory
      )
  AND i.inv_item_sk NOT IN (
        SELECT ws_item_sk
        FROM web_sales
        WHERE ws_sold_date_sk = 2451011
      )
  AND i.inv_item_sk IN (
        SELECT item_sk
        FROM item_set
      )
  AND NOT EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk
          AND ws2.ws_item_sk = i.inv_item_sk
          AND ws2.ws_sold_date_sk = 2452394
      )
GROUP BY w.w_warehouse_id, w.w_city
ORDER BY total_sales DESC
LIMIT 100
