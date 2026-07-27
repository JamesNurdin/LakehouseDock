WITH
    ws_base AS (
        SELECT
            ws.ws_sold_date_sk,
            ws.ws_sold_time_sk,
            ws.ws_item_sk,
            ws.ws_ship_mode_sk,
            ws.ws_warehouse_sk,
            ws.ws_web_page_sk,
            ws.ws_bill_cdemo_sk,
            ws.ws_ship_cdemo_sk,
            ws.ws_order_number,
            ws.ws_net_profit,
            ws.ws_net_paid,
            ws.ws_ext_wholesale_cost
        FROM web_sales ws
    ),
    wr_base AS (
        SELECT
            wr.wr_order_number,
            wr.wr_item_sk,
            wr.wr_returned_time_sk,
            wr.wr_return_amt,
            wr.wr_return_tax,
            wr.wr_return_amt_inc_tax,
            wr.wr_fee,
            wr.wr_return_ship_cost,
            wr.wr_refunded_cash,
            wr.wr_net_loss,
            wr.wr_web_page_sk
        FROM web_returns wr
    ),
    cr_base AS (
        SELECT
            cr.cr_order_number,
            cr.cr_item_sk,
            cr.cr_returned_time_sk,
            cr.cr_return_amount,
            cr.cr_return_tax,
            cr.cr_return_amt_inc_tax,
            cr.cr_fee,
            cr.cr_return_ship_cost,
            cr.cr_refunded_cash,
            cr.cr_net_loss,
            cr.cr_ship_mode_sk,
            cr.cr_warehouse_sk,
            cr.cr_refunded_cdemo_sk
        FROM catalog_returns cr
    )
SELECT
    i.i_item_id,
    i.i_brand,
    sm.sm_type,
    w.w_warehouse_name,
    cd_ref.cd_gender,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(i.i_current_price) AS avg_item_price,
    MIN(ws.ws_sold_date_sk) AS first_sold_date_sk,
    MAX(ws.ws_sold_date_sk) AS last_sold_date_sk
FROM ws_base ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN wr_base wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN cr_base cr ON cr.cr_item_sk = i.i_item_sk
    AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    AND cr.cr_warehouse_sk = w.w_warehouse_sk
    AND cr.cr_returned_time_sk = ws.ws_sold_time_sk
JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
WHERE i.i_current_price > 100.00
  AND wp.wp_image_count >= 4
  AND w.w_warehouse_sq_ft > 600000
GROUP BY i.i_item_id, i.i_brand, sm.sm_type, w.w_warehouse_name, cd_ref.cd_gender
ORDER BY total_net_profit DESC
LIMIT 100
