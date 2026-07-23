SELECT
    cc.cc_name AS call_center_name,
    cp.cp_type AS catalog_page_type,
    d_sold.d_year AS sales_year,
    sm.sm_type AS ship_mode_type,
    cd_bill.cd_gender AS customer_gender,
    ws.web_name AS website_name,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    (SELECT AVG(cs_inner.cs_net_profit) FROM catalog_sales cs_inner) AS avg_net_profit_all
FROM
    catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d_return ON cr.cr_returned_date_sk = d_return.d_date_sk
    JOIN time_dim t_return ON cr.cr_returned_time_sk = t_return.t_time_sk
    JOIN store_returns sr ON sr.sr_customer_sk = c_bill.c_customer_sk
    JOIN date_dim d_sr_return ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
    JOIN time_dim t_sr_return ON sr.sr_return_time_sk = t_sr_return.t_time_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN web_page wp ON wp.wp_customer_sk = c_bill.c_customer_sk
    JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
WHERE
    d_sold.d_year BETWEEN 1999 AND 2001
    AND cd_bill.cd_gender = 'M'
GROUP BY
    cc.cc_name,
    cp.cp_type,
    d_sold.d_year,
    sm.sm_type,
    cd_bill.cd_gender,
    ws.web_name
ORDER BY
    total_net_profit DESC,
    sales_year ASC
LIMIT 100
