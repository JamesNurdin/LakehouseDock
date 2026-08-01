SELECT
    cc.cc_name AS call_center_name,
    w.w_city AS warehouse_city,
    d_sold.d_year AS sales_year,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(ss.ss_ext_tax) AS total_store_sales_tax,
    MAX(wp.wp_url) AS sample_web_page_url
FROM tpcds.catalog_sales cs
JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN tpcds.date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN tpcds.date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN tpcds.customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN tpcds.customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN tpcds.customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN tpcds.customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
LEFT JOIN tpcds.web_page wp
    ON wp.wp_customer_sk = c_bill.c_customer_sk
LEFT JOIN tpcds.date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN tpcds.store_sales ss
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
   AND ss.ss_customer_sk = c_bill.c_customer_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.catalog_returns cr
    WHERE cr.cr_order_number = cs.cs_order_number
)
GROUP BY
    cc.cc_name,
    w.w_city,
    d_sold.d_year
ORDER BY total_net_paid DESC
LIMIT 100
