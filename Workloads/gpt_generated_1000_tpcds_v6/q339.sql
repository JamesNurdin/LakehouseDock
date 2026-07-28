/*
Goal: Compute sales, return and inventory metrics by item category and warehouse state, filtering to specific manufacturers, high‑value sales, and profitable returns, while joining all eight selected TPC‑DS tables.
*/
WITH
    item_f AS (
        SELECT i_item_sk,
               i_category,
               i_class,
               i_manufact_id,
               i_current_price
        FROM   item
        WHERE  i_manufact_id IN (169, 212)
    ),
    inv_f AS (
        SELECT inv_item_sk,
               inv_warehouse_sk,
               inv_quantity_on_hand
        FROM   inventory
        WHERE  inv_quantity_on_hand > 600
    ),
    cr_f AS (
        SELECT cr_item_sk,
               cr_warehouse_sk,
               cr_return_quantity,
               cr_net_loss,
               cr_refunded_cdemo_sk
        FROM   catalog_returns
        WHERE  cr_net_loss > 0
    ),
    ws_f AS (
        SELECT ws_item_sk,
               ws_warehouse_sk,
               ws_order_number,
               ws_ext_sales_price,
               ws_sold_date_sk,
               ws_ship_mode_sk,
               ws_bill_cdemo_sk
        FROM   web_sales
        WHERE  ws_ext_sales_price > 100
    ),
    wr_f AS (
        SELECT wr_item_sk,
               wr_order_number,
               wr_return_quantity,
               wr_net_loss,
               wr_returned_date_sk,
               wr_refunded_cdemo_sk
        FROM   web_returns
        WHERE  wr_net_loss > 0
    ),
    cd_ref AS (
        SELECT cd_demo_sk,
               cd_gender,
               cd_marital_status,
               cd_credit_rating
        FROM   customer_demographics
        WHERE  cd_credit_rating = 'Excellent'
    ),
    ship AS (
        SELECT sm_ship_mode_sk,
               sm_type
        FROM   ship_mode
        WHERE  sm_type = 'AIR'
    ),
    wh AS (
        SELECT w_warehouse_sk,
               w_state,
               w_city
        FROM   warehouse
        WHERE  w_state IN ('CA', 'TX')
    )
SELECT
    i_f.i_category,
    wh.w_state,
    COUNT(DISTINCT ws_f.ws_order_number)                           AS order_cnt,
    SUM(ws_f.ws_ext_sales_price)                                   AS total_sales,
    SUM(cr_f.cr_return_quantity)                                   AS total_return_qty,
    SUM(cr_f.cr_net_loss)                                          AS total_return_loss,
    AVG(inv_f.inv_quantity_on_hand)                                AS avg_inventory_qty,
    (SELECT MAX(i_current_price) FROM item WHERE i_manufact_id = 169) AS max_price_manuf_169
FROM
    ws_f
    JOIN item_f i_f
        ON ws_f.ws_item_sk = i_f.i_item_sk
    JOIN wh
        ON ws_f.ws_warehouse_sk = wh.w_warehouse_sk
    JOIN ship
        ON ws_f.ws_ship_mode_sk = ship.sm_ship_mode_sk
    JOIN cd_ref cd_bill
        ON ws_f.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN cr_f
        ON cr_f.cr_item_sk = i_f.i_item_sk
        AND cr_f.cr_warehouse_sk = wh.w_warehouse_sk
    JOIN wr_f
        ON wr_f.wr_item_sk = i_f.i_item_sk
        AND wr_f.wr_order_number = ws_f.ws_order_number
    JOIN inv_f
        ON inv_f.inv_item_sk = i_f.i_item_sk
        AND inv_f.inv_warehouse_sk = wh.w_warehouse_sk
WHERE EXISTS (
        SELECT 1
        FROM   catalog_returns cr2
        WHERE  cr2.cr_item_sk = ws_f.ws_item_sk
          AND  cr2.cr_net_loss > 50
    )
GROUP BY ROLLUP (i_f.i_category, wh.w_state)
HAVING SUM(ws_f.ws_ext_sales_price) > 500
ORDER BY i_f.i_category NULLS LAST, wh.w_state NULLS LAST
