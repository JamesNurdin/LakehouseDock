WITH inv_avg AS (
    SELECT
        inv_item_sk,
        inv_date_sk,
        AVG(inv_quantity_on_hand) OVER (PARTITION BY inv_item_sk) AS avg_qty
    FROM inventory
)
SELECT
    ws.ws_order_number,
    d_sold.d_date AS sold_date,
    d_ship.d_date AS ship_date,
    s.s_store_id,
    s.s_city,
    w.w_warehouse_id,
    ws.ws_net_paid_inc_ship_tax,
    CASE
        WHEN i.inv_quantity_on_hand > a.avg_qty THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS inventory_level,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ws.ws_net_paid_inc_ship_tax DESC) AS rn_store_sales
FROM web_sales ws
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN warehouse w
  ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN inventory i
  ON i.inv_date_sk = d_ship.d_date_sk
  AND i.inv_warehouse_sk = w.w_warehouse_sk
JOIN inv_avg a
  ON a.inv_item_sk = i.inv_item_sk
  AND a.inv_date_sk = i.inv_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_ship.d_date_sk
WHERE d_sold.d_year = 2001
  AND ws.ws_net_paid_inc_ship_tax > 1000
  AND s.s_state = 'CA'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_store_sk = s.s_store_sk
          AND sr.sr_returned_date_sk = d_sold.d_date_sk
          AND sr.sr_return_amt > 0
      )
ORDER BY ws.ws_net_paid_inc_ship_tax DESC
LIMIT 100
