WITH joined_data AS (
    SELECT
        w.w_warehouse_name,
        cc.cc_name,
        cp.cp_department,
        ws.ws_net_paid,
        ws.ws_net_profit,
        cr.cr_return_amount,
        wr.wr_return_amt,
        inv.inv_quantity_on_hand,
        d_sold.d_year
    FROM call_center cc
    JOIN catalog_returns cr
        ON cc.cc_call_center_sk = cr.cr_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret
        ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN customer c_refunded
        ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer c_returning
        ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN web_sales ws
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer c_ship
        ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
    JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN customer c_refunded_wr
        ON wr.wr_refunded_customer_sk = c_refunded_wr.c_customer_sk
    JOIN customer c_returning_wr
        ON wr.wr_returning_customer_sk = c_returning_wr.c_customer_sk
    JOIN web_page wp_wr
        ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN date_dim d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close
        ON cc.cc_closed_date_sk = d_close.d_date_sk
    JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN customer c_wp
        ON wp.wp_customer_sk = c_wp.c_customer_sk
    WHERE d_sold.d_year = 2001
),
aggregated AS (
    SELECT
        w_warehouse_name,
        cc_name,
        cp_department,
        SUM(ws_net_paid) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        SUM(cr_return_amount) AS total_catalog_returns,
        SUM(wr_return_amt) AS total_web_returns,
        SUM(inv_quantity_on_hand) AS total_inventory_on_hand
    FROM joined_data
    GROUP BY
        w_warehouse_name,
        cc_name,
        cp_department
)
SELECT
    w_warehouse_name,
    cc_name,
    cp_department,
    total_sales,
    total_profit,
    total_catalog_returns,
    total_web_returns,
    total_inventory_on_hand,
    (total_profit - (total_catalog_returns + total_web_returns)) AS net_adj_profit,
    CASE
        WHEN (total_profit - (total_catalog_returns + total_web_returns)) > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_status,
    ROW_NUMBER() OVER (ORDER BY (total_profit - (total_catalog_returns + total_web_returns)) DESC) AS profit_rank
FROM aggregated
ORDER BY net_adj_profit DESC
LIMIT 100
