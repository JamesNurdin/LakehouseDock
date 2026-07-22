SELECT
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    w.w_warehouse_name,
    ws.web_name,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    SUM(i.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT hd.hd_demo_sk) AS hd_count,
    CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status
FROM
    catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
        AND cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cp.cp_end_date_sk = d.d_date_sk
        AND cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_call_center_sk = cc.cc_call_center_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
        AND i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND s.s_state = 'CA'
    AND cc.cc_city = 'Salem'
    AND cp.cp_department = 'Electronics'
    AND w.w_state = 'TX'
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_store_name,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    w.w_warehouse_name,
    ws.web_name
ORDER BY
    total_sales DESC,
    d.d_year,
    d.d_month_seq
LIMIT 100
