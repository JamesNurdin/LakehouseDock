WITH ss_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ARRAY[ss.ss_quantity, ss.ss_ext_sales_price] AS qty_price_arr
    FROM store_sales ss
    WHERE ss.ss_quantity > 0
)
SELECT
    s.s_store_id,
    s.s_state,
    cp.cp_department,
    sm.sm_carrier,
    w.w_warehouse_name,
    SUM(CASE WHEN u.metric_idx = 1 THEN u.metric END) AS total_quantity,
    SUM(CASE WHEN u.metric_idx = 2 THEN u.metric END) AS total_store_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
    AVG(i.i_current_price) AS avg_item_price,
    MIN(d_ss.d_date) AS first_store_sale_date,
    CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_category,
    (SELECT COUNT(DISTINCT i2.i_item_id) FROM item i2) AS total_distinct_items,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY SUM(CASE WHEN u.metric_idx = 2 THEN u.metric END) DESC) AS store_rank_in_state
FROM ss_base
CROSS JOIN UNNEST(ss_base.qty_price_arr) WITH ORDINALITY AS u(metric, metric_idx)
JOIN date_dim d_ss ON ss_base.ss_sold_date_sk = d_ss.d_date_sk
JOIN time_dim t_ss ON ss_base.ss_sold_time_sk = t_ss.t_time_sk
JOIN item i ON ss_base.ss_item_sk = i.i_item_sk
JOIN store s ON ss_base.ss_store_sk = s.s_store_sk
JOIN customer c ON ss_base.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss_base.ss_ticket_number
    AND sr.sr_item_sk = ss_base.ss_item_sk
JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    AND ws.ws_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN time_dim t_ws_sold ON ws.ws_sold_time_sk = t_ws_sold.t_time_sk
JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_ss.d_date_sk
WHERE
    d_ss.d_year = 1998
    AND i.i_brand = 'Brand#12'
    AND cd.cd_gender = 'M'
    AND s.s_state = 'CA'
    AND sm.sm_carrier = 'UPS'
    AND cp.cp_department = 'Electronics'
GROUP BY
    s.s_store_id,
    s.s_state,
    cp.cp_department,
    sm.sm_carrier,
    w.w_warehouse_name,
    cd.cd_gender
ORDER BY total_store_sales DESC
LIMIT 100
