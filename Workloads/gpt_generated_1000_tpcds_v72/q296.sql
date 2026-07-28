WITH base AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cp.cp_department,
        cp.cp_catalog_number,
        r.r_reason_desc,
        td.t_hour AS td_hour,
        w_ret.w_warehouse_name        AS ret_warehouse,
        w_sales.w_warehouse_name      AS sales_warehouse,
        ws.ws_net_paid_inc_ship_tax   AS ws_net_paid_inc_ship_tax,
        ws.ws_net_profit               AS ws_net_profit,
        CASE WHEN cr.cr_return_quantity > 1 THEN 'Multiple' ELSE 'Single' END AS return_qty_flag,
        inv_agg.total_qty_on_hand
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w_ret
        ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
    JOIN household_demographics hd_refund
        ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN household_demographics hd_return
        ON cr.cr_returning_hdemo_sk = hd_return.hd_demo_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN warehouse w_sales
        ON ws.ws_warehouse_sk = w_sales.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    CROSS JOIN LATERAL (
        SELECT SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory inv
        WHERE inv.inv_warehouse_sk = w_sales.w_warehouse_sk
    ) AS inv_agg
    WHERE td.t_hour BETWEEN 9 AND 17
)
SELECT
    ret_warehouse,
    sales_warehouse,
    cp_department,
    cp_catalog_number,
    r_reason_desc,
    td_hour,
    return_qty_flag,
    SUM(cr_return_amount)                     AS total_return_amount,
    SUM(cr_net_loss)                          AS total_net_loss,
    SUM(ws_net_paid_inc_ship_tax)             AS total_sales_inc_tax,
    SUM(ws_net_profit)                        AS total_net_profit,
    SUM(CASE WHEN ws_net_profit > 0 THEN ws_net_profit ELSE 0 END) AS positive_profit,
    AVG(total_qty_on_hand)                    AS avg_inventory_qty
FROM base
GROUP BY
    ret_warehouse,
    sales_warehouse,
    cp_department,
    cp_catalog_number,
    r_reason_desc,
    td_hour,
    return_qty_flag
ORDER BY total_net_profit DESC
LIMIT 100
