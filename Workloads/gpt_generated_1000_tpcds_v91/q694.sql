WITH ws AS (
    SELECT 
        ws_order_number,
        ws_sold_date_sk,
        ws_sold_time_sk,
        ws_ship_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ws_warehouse_sk,
        ws_ship_mode_sk,
        ws_web_page_sk,
        ws_bill_cdemo_sk,
        ws_ship_cdemo_sk
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2002)
),
wr AS (
    SELECT 
        wr_order_number,
        wr_returned_date_sk,
        wr_returned_time_sk,
        wr_item_sk,
        wr_return_quantity,
        wr_net_loss,
        wr_reason_sk,
        wr_refunded_cdemo_sk,
        wr_returning_cdemo_sk,
        wr_web_page_sk
    FROM web_returns
    WHERE wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2002)
),
sr AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_item_sk,
        sr_cdemo_sk,
        sr_reason_sk,
        sr_net_loss,
        sr_return_quantity
    FROM store_returns
    WHERE sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2002)
)
SELECT 
    d_sold.d_year,
    sm.sm_type,
    r_wr.r_reason_desc AS web_return_reason,
    r_sr.r_reason_desc AS store_return_reason,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(wr.wr_net_loss) AS total_web_return_loss,
    SUM(sr.sr_net_loss) AS total_store_return_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_quantity,
    AVG(cd_bill.cd_purchase_estimate) AS avg_customer_purchase_estimate,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    AVG(
        (SELECT MAX(cd2.cd_purchase_estimate)
         FROM customer_demographics cd2
         WHERE cd2.cd_gender = cd_bill.cd_gender)
    ) AS avg_max_purchase_estimate_for_gender,
    (SELECT COUNT(DISTINCT wr3.wr_order_number)
     FROM web_returns wr3
     JOIN date_dim d3 ON wr3.wr_returned_date_sk = d3.d_date_sk
     WHERE d3.d_year = d_sold.d_year) AS distinct_web_return_orders_year
FROM ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold
    ON ws.ws_sold_time_sk = t_sold.t_time_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN inventory inv
    ON inv.inv_date_sk = d_sold.d_date_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN sr
    ON sr.sr_returned_date_sk = d_sold.d_date_sk
    AND sr.sr_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
JOIN date_dim d_wr_return
    ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
JOIN time_dim t_wr_return
    ON wr.wr_returned_time_sk = t_wr_return.t_time_sk
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN customer_demographics cd_refunded
    ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN web_page wp_wr
    ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
CROSS JOIN LATERAL (
    SELECT ARRAY[ws.ws_quantity, ws.ws_item_sk] AS arr
) AS t(arr)
CROSS JOIN UNNEST(t.arr) AS u(value)
GROUP BY d_sold.d_year, sm.sm_type, r_wr.r_reason_desc, r_sr.r_reason_desc
ORDER BY total_net_profit DESC
LIMIT 100
