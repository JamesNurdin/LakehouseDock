SELECT
    s.s_store_name,
    i.i_category,
    d_sold.d_year,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_transactions,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(wr.wr_return_amt) AS total_return_amount,
    CASE
        WHEN (SUM(ss.ss_ext_sales_price) + SUM(cs.cs_ext_sales_price)) > 100000 THEN 'High'
        ELSE 'Low'
    END AS sales_volume_category,
    ROUND(AVG(i.i_wholesale_cost), 2) AS avg_item_wholesale_cost,
    MAX(ss.ss_ext_sales_price) AS max_store_sale_price,
    MIN(cs.cs_ext_sales_price) AS min_catalog_sale_price
FROM
    store_sales ss
    JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_store_close ON s.s_closed_date_sk = d_store_close.d_date_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_date_sk = d_sold.d_date_sk
        AND cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d_wr_return ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN customer c_wp ON wp.wp_customer_sk = c_wp.c_customer_sk
    JOIN customer c_refunded ON wr.wr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer_demographics cd_refunded ON wr.wr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer_address ca_refunded ON wr.wr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer c_returning ON wr.wr_returning_customer_sk = c_returning.c_customer_sk
    JOIN customer_demographics cd_returning ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN customer_address ca_returning ON wr.wr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN web_site ws ON TRUE
    JOIN date_dim d_ws_open ON ws.web_open_date_sk = d_ws_open.d_date_sk
    JOIN date_dim d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
WHERE
    i.i_manufact_id = 260
    AND s.s_state = 'CA'
    AND d_sold.d_year = 2001
    AND sm.sm_contract = 'A5BYO1qH8HGTTN'
    AND t_sold.t_hour BETWEEN 8 AND 18
GROUP BY
    s.s_store_name,
    i.i_category,
    d_sold.d_year
ORDER BY
    total_store_sales DESC
OFFSET 0
LIMIT 100
