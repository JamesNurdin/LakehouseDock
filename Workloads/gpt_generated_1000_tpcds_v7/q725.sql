WITH
    -- Base returns
    wr AS (
        SELECT *
        FROM web_returns
    ),
    -- Time dimension for the return moment
    t_ret AS (
        SELECT t_time_sk, t_hour, t_am_pm, t_minute
        FROM time_dim
    ),
    -- Item dimension (joined through the return item)
    i AS (
        SELECT i_item_sk, i_manufact_id, i_brand, i_category
        FROM item
    ),
    -- Current inventory snapshot (first alias)
    inv_cur AS (
        SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
        FROM inventory
    ),
    -- Warehouse for the current inventory
    w_cur AS (
        SELECT w_warehouse_sk, w_warehouse_name, w_state
        FROM warehouse
    ),
    -- Historical inventory snapshot (second alias of inventory)
    inv_hist AS (
        SELECT inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
        FROM inventory
    ),
    -- Warehouse for the historical inventory
    w_hist AS (
        SELECT w_warehouse_sk, w_warehouse_name
        FROM warehouse
    )
SELECT
    i.i_manufact_id,
    i.i_brand,
    w_cur.w_warehouse_name      AS current_warehouse,
    w_hist.w_warehouse_name     AS historical_warehouse,
    t_ret.t_hour,
    t_ret.t_am_pm,
    SUM(wr.wr_return_quantity)  AS total_return_qty,
    SUM(wr.wr_return_amt)       AS total_return_amount,
    SUM(inv_cur.inv_quantity_on_hand)  AS total_current_qty_on_hand,
    SUM(inv_hist.inv_quantity_on_hand) AS total_historical_qty_on_hand,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
FROM web_returns wr
JOIN time_dim t_ret
  ON wr.wr_returned_time_sk = t_ret.t_time_sk
JOIN item i
  ON wr.wr_item_sk = i.i_item_sk
JOIN inventory inv_cur
  ON i.i_item_sk = inv_cur.inv_item_sk
JOIN warehouse w_cur
  ON inv_cur.inv_warehouse_sk = w_cur.w_warehouse_sk
JOIN inventory inv_hist
  ON i.i_item_sk = inv_hist.inv_item_sk
JOIN warehouse w_hist
  ON inv_hist.inv_warehouse_sk = w_hist.w_warehouse_sk
WHERE t_ret.t_am_pm = 'PM'
  AND i.i_manufact_id IN (26, 630, 167)
  AND inv_cur.inv_quantity_on_hand > 0
GROUP BY
    i.i_manufact_id,
    i.i_brand,
    w_cur.w_warehouse_name,
    w_hist.w_warehouse_name,
    t_ret.t_hour,
    t_ret.t_am_pm
ORDER BY total_return_amount DESC
LIMIT 100
