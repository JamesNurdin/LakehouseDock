WITH item_filtered AS (
    SELECT i_item_sk,
           i_brand,
           i_manufact_id,
           i_size,
           i_class_id,
           i_category,
           i_current_price
    FROM item
    WHERE i_manufact_id IN (167, 995)
      AND i_size = 'medium'
      AND i_class_id = 2
),
warehouse_filtered AS (
    SELECT w_warehouse_sk,
           w_state,
           w_city
    FROM warehouse
    WHERE w_state = 'CA'
),
inventory_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 50
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    t.t_hour,
    w.w_state,
    i.i_brand,
    COUNT(DISTINCT cr.cr_order_number)                     AS cnt_catalog_returns,
    SUM(cr.cr_return_amount)                               AS sum_catalog_return_amount,
    SUM(wr.wr_return_amt)                                 AS sum_web_return_amt,
    SUM(ws.ws_ext_sales_price)                             AS sum_sales_price,
    inv.total_on_hand,
    AVG(i.i_current_price)                                 AS avg_current_price,
    ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS brand_sales_rank
FROM catalog_returns cr
JOIN time_dim t
     ON cr.cr_returned_time_sk = t.t_time_sk
JOIN item_filtered i
     ON cr.cr_item_sk = i.i_item_sk
JOIN warehouse_filtered w
     ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inventory_agg inv
     ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
     ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_warehouse_sk = w.w_warehouse_sk
    AND ws.ws_sold_time_sk = t.t_time_sk
JOIN web_returns wr
     ON wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
WHERE cr.cr_return_amount > 100
  AND cr.cr_reversed_charge > 100
  AND ws.ws_ship_mode_sk IN (5, 13)
  AND t.t_hour BETWEEN 9 AND 17
  AND wr.wr_return_amt > 50
  AND EXISTS (
        SELECT 1
        FROM web_sales ws2
        WHERE ws2.ws_order_number = ws.ws_order_number
          AND ws2.ws_net_profit > 0
      )
GROUP BY
    t.t_hour,
    w.w_state,
    i.i_brand,
    inv.total_on_hand,
    i.i_current_price
ORDER BY sum_sales_price DESC
LIMIT 100
