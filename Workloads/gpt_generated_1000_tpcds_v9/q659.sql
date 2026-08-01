SELECT
    cp.cp_catalog_page_id,
    p.p_promo_id,
    ca_bill.ca_state,
    d_sold.d_year AS sales_year,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_returns,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_count,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
    AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
    AVG(ws.ws_ext_discount_amt) AS avg_web_discount
FROM
    store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON ss.ss_sold_time_sk = t_sold.t_time_sk
    JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN date_dim d_ws_sold
        ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
    JOIN time_dim t_ws_sold
        ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
    JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN customer c_bill
        ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer c_ship
        ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN customer c_wp
        ON wp.wp_customer_sk = c_wp.c_customer_sk
    JOIN web_site w_site
        ON ws.ws_web_site_sk = w_site.web_site_sk
    JOIN date_dim d_ws_open
        ON w_site.web_open_date_sk = d_ws_open.d_date_sk
    JOIN date_dim d_ws_close
        ON w_site.web_close_date_sk = d_ws_close.d_date_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
           AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN date_dim d_wr_ret
        ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
    LEFT JOIN time_dim t_wr_ret
        ON wr.wr_returned_time_sk = t_wr_ret.t_time_sk
    JOIN catalog_page cp
        ON 1 = 1
    JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
WHERE
    NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_refunded_customer_sk = c_bill.c_customer_sk
    )
GROUP BY
    cp.cp_catalog_page_id,
    p.p_promo_id,
    ca_bill.ca_state,
    d_sold.d_year
HAVING
    SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) > 5000
ORDER BY
    (total_store_sales + total_web_sales) DESC
LIMIT 100
