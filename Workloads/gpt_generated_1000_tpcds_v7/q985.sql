WITH
    cr AS (
        SELECT *
        FROM catalog_returns
    ),
    d_return AS (
        SELECT *
        FROM date_dim
    ),
    t_return AS (
        SELECT *
        FROM time_dim
    ),
    i AS (
        SELECT *
        FROM item
    ),
    r AS (
        SELECT *
        FROM reason
    ),
    w AS (
        SELECT *
        FROM warehouse
    ),
    cc AS (
        SELECT *
        FROM call_center
    ),
    c_ref AS (
        SELECT *
        FROM customer
    ),
    ca_ref AS (
        SELECT *
        FROM customer_address
    ),
    cd_ref AS (
        SELECT *
        FROM customer_demographics
    ),
    ws AS (
        SELECT *
        FROM web_sales
    ),
    d_ship AS (
        SELECT *
        FROM date_dim
    ),
    wr AS (
        SELECT *
        FROM web_returns
    ),
    inv AS (
        SELECT *
        FROM inventory
    ),
    wp AS (
        SELECT *
        FROM web_page
    )
SELECT
    w.w_warehouse_id,
    w.w_state,
    i.i_category,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(ws.ws_net_paid) AS total_web_sales_net_paid,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT c_ref.c_customer_id) AS distinct_customers
FROM catalog_returns cr
INNER JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
INNER JOIN time_dim t_return
    ON cr.cr_returned_time_sk = t_return.t_time_sk
INNER JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
INNER JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
INNER JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
INNER JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
INNER JOIN customer c_ref
    ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
INNER JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
INNER JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
INNER JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
INNER JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
INNER JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_order_number = ws.ws_order_number
INNER JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d_return.d_date_sk
INNER JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
GROUP BY
    w.w_warehouse_id,
    w.w_state,
    i.i_category
HAVING
    SUM(ws.ws_net_paid) > 0
ORDER BY
    total_web_sales_net_paid DESC
