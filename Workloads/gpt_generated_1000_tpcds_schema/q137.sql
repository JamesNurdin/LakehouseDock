/*
  Goal: Identify warehouses in the United States with high return amounts, rank them by total return amount, and within each warehouse rank inventory items by quantity on hand, using a sampled subset of returns and several filters.
*/
WITH sampled_returns AS (
    SELECT cr_returned_date_sk,
           cr_returned_time_sk,
           cr_item_sk,
           cr_refunded_customer_sk,
           cr_refunded_cdemo_sk,
           cr_refunded_hdemo_sk,
           cr_refunded_addr_sk,
           cr_returning_customer_sk,
           cr_returning_cdemo_sk,
           cr_returning_hdemo_sk,
           cr_returning_addr_sk,
           cr_call_center_sk,
           cr_catalog_page_sk,
           cr_ship_mode_sk,
           cr_warehouse_sk,
           cr_reason_sk,
           cr_order_number,
           cr_return_quantity,
           cr_return_amount,
           cr_return_tax,
           cr_return_amt_inc_tax,
           cr_fee,
           cr_return_ship_cost,
           cr_refunded_cash,
           cr_reversed_charge,
           cr_store_credit,
           cr_net_loss
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)   -- Sample ~10% of rows
    WHERE cr_returning_cdemo_sk IN (1843052, 1740425, 1793803, 488420)
      AND cr_return_amount > 100
),
warehouse_filtered AS (
    SELECT w_warehouse_sk,
           w_warehouse_id,
           w_warehouse_name,
           w_warehouse_sq_ft,
           w_suite_number
    FROM warehouse
    WHERE w_country = 'United States'
      AND w_warehouse_sq_ft BETWEEN 50000 AND 1000000
      AND w_suite_number LIKE 'Suite %'
),
inventory_filtered AS (
    SELECT inv_date_sk,
           inv_item_sk,
           inv_warehouse_sk,
           inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand >= 100
      AND inv_item_sk IN (101438, 101432, 101419)
)
SELECT
    wf.w_warehouse_id,
    wf.w_warehouse_name,
    SUM(sr.cr_return_amount)                                 AS total_return_amount,
    SUM(sr.cr_return_quantity)                               AS total_return_quantity,
    COUNT(DISTINCT sr.cr_order_number)                       AS distinct_order_cnt,
    inv.inv_item_sk,
    inv.inv_quantity_on_hand,
    ROW_NUMBER() OVER (
        PARTITION BY wf.w_warehouse_id
        ORDER BY inv.inv_quantity_on_hand DESC
    )                                                         AS item_rank_by_qty,
    RANK() OVER (ORDER BY SUM(sr.cr_return_amount) DESC)    AS warehouse_return_amount_rank
FROM sampled_returns sr
JOIN warehouse_filtered wf
  ON sr.cr_warehouse_sk = wf.w_warehouse_sk
JOIN inventory_filtered inv
  ON inv.inv_warehouse_sk = wf.w_warehouse_sk
GROUP BY wf.w_warehouse_id,
         wf.w_warehouse_name,
         inv.inv_item_sk,
         inv.inv_quantity_on_hand,
         wf.w_warehouse_sq_ft,
         wf.w_suite_number
ORDER BY warehouse_return_amount_rank,
         wf.w_warehouse_id,
         item_rank_by_qty
LIMIT 100
