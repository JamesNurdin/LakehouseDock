SELECT
    d_year.d_year AS year,
    i.i_brand AS brand,
    cc.cc_name AS call_center_name,
    w.w_warehouse_name AS warehouse_name,
    r_cr.r_reason_desc AS return_reason,
    ca_ss.ca_state AS customer_state,
    t_store_sales.t_hour AS hour_of_day,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(cr.cr_return_amount) AS total_catalog_returns,
    SUM(wr.wr_return_amt) AS total_web_returns,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    AVG(ws.ws_sales_price) AS avg_web_sales_price,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
    SUM(ss.ss_quantity) AS total_store_qty,
    SUM(ws.ws_quantity) AS total_web_qty,
    CASE
        WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_flag
FROM
    date_dim d_year
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d_year.d_date_sk
    LEFT JOIN time_dim t_store_sales
        ON ss.ss_sold_time_sk = t_store_sales.t_time_sk
    LEFT JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN customer c_ss
        ON ss.ss_customer_sk = c_ss.c_customer_sk
    LEFT JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    LEFT JOIN call_center cc
        ON cc.cc_closed_date_sk = d_year.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_returned_date_sk = d_year.d_date_sk
    LEFT JOIN time_dim t_cr_returned
        ON cr.cr_returned_time_sk = t_cr_returned.t_time_sk
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d_year.d_date_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_year.d_date_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN time_dim t_ws_sold
        ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN customer c_ws
        ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
    LEFT JOIN customer_address ca_ws
        ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_date_sk = d_year.d_date_sk
    LEFT JOIN time_dim t_wr_returned
        ON wr.wr_returned_time_sk = t_wr_returned.t_time_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN web_page wp_wr
        ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
    LEFT JOIN customer c_wr
        ON wr.wr_refunded_customer_sk = c_wr.c_customer_sk
    LEFT JOIN customer_address ca_wr
        ON wr.wr_refunded_addr_sk = ca_wr.ca_address_sk
WHERE
    d_year.d_year = 1999
    AND i.i_category = 'Sports'
    AND i.i_manager_id IN (6, 13)
    AND cc.cc_state = 'CA'
    AND w.w_state = 'CA'
    AND ca_ss.ca_country = 'United States'
    AND r_cr.r_reason_desc = 'Damaged'
    AND t_store_sales.t_hour BETWEEN 8 AND 12
GROUP BY
    d_year.d_year,
    i.i_brand,
    cc.cc_name,
    w.w_warehouse_name,
    r_cr.r_reason_desc,
    ca_ss.ca_state,
    t_store_sales.t_hour
ORDER BY
    total_store_sales DESC
LIMIT 100
