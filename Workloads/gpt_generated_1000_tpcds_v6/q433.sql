WITH ws AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_sold_time_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk
    FROM web_sales ws
),
wr AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_returned_time_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_returning_hdemo_sk
    FROM web_returns wr
)
SELECT
    i.i_category,
    sm.sm_type,
    hd_bill.hd_income_band_sk,
    td_sold.t_hour,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_qty,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
FROM ws
JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
JOIN household_demographics hd_bill
    ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship
    ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN time_dim td_sold
    ON ws.ws_sold_time_sk = td_sold.t_time_sk
LEFT JOIN wr
    ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
LEFT JOIN time_dim td_return
    ON wr.wr_returned_time_sk = td_return.t_time_sk
LEFT JOIN household_demographics hd_refunded
    ON wr.wr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
LEFT JOIN household_demographics hd_returning
    ON wr.wr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE EXISTS (
    SELECT 1
    FROM inventory inv2
    WHERE inv2.inv_item_sk = i.i_item_sk
      AND inv2.inv_quantity_on_hand > 0
      AND inv2.inv_warehouse_sk = w.w_warehouse_sk
) 
  AND i.i_current_price > 20
GROUP BY GROUPING SETS (
    (i.i_category, sm.sm_type, hd_bill.hd_income_band_sk, td_sold.t_hour),
    (i.i_category, sm.sm_type, hd_bill.hd_income_band_sk),
    (i.i_category, sm.sm_type),
    (i.i_category),
    ()
)
ORDER BY total_profit DESC
LIMIT 100
