/* goal: Calculate total sales and returns across catalog, store, and web channels by year, shipping mode, item brand, and customer gender. */
WITH joined_data AS (
    SELECT
        d.d_year,
        sm.sm_type,
        i.i_brand,
        cd.cd_gender,
        cs.cs_net_paid,
        cr.cr_return_amount,
        ss.ss_net_paid,
        ws.ws_net_paid,
        c.c_customer_sk,
        i.i_current_price
    FROM tpcds.date_dim d
    JOIN tpcds.catalog_page cp
        ON cp.cp_start_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.item i
        ON i.i_item_sk = cr.cr_item_sk
    JOIN tpcds.ship_mode sm
        ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
    JOIN tpcds.warehouse w
        ON w.w_warehouse_sk = cr.cr_warehouse_sk
    JOIN tpcds.customer c
        ON c.c_customer_sk = cr.cr_refunded_customer_sk
    JOIN tpcds.customer_demographics cd
        ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN tpcds.time_dim t
        ON t.t_time_sk = cr.cr_returned_time_sk
    JOIN tpcds.store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
    JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN tpcds.web_site wsit
        ON wsit.web_open_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND cd.cd_gender = 'F'
      AND i.i_brand = 'Brand#23'
)
SELECT
    d_year,
    sm_type,
    i_brand,
    cd_gender,
    SUM(cs_net_paid)        AS total_catalog_sales,
    SUM(cr_return_amount)   AS total_catalog_returns,
    SUM(ss_net_paid)        AS total_store_sales,
    SUM(ws_net_paid)        AS total_web_sales,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers,
    AVG(i_current_price)    AS avg_item_price
FROM joined_data
GROUP BY d_year, sm_type, i_brand, cd_gender
