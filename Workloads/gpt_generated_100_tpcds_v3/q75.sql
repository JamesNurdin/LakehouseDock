SELECT
    cp.cp_department AS department,
    sm.sm_type AS ship_type,
    d_sold.d_year AS sales_year,
    sum(cs.cs_net_paid) AS total_net_paid,
    sum(sr.sr_return_amt) AS total_return_amount,
    sum(cs.cs_quantity) AS total_quantity,
    avg(cs.cs_quantity) AS avg_quantity,
    count(DISTINCT c_bill.c_customer_sk) AS distinct_customers,
    (SELECT avg(cs2.cs_net_profit) FROM catalog_sales cs2) AS overall_avg_profit
FROM
    catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN customer c_bill
    ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer c_ship
    ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN store_returns sr
    ON sr.sr_customer_sk = c_bill.c_customer_sk
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN customer_demographics cd_ret
    ON sr.sr_cdemo_sk = cd_ret.cd_demo_sk
JOIN customer c_ret
    ON sr.sr_customer_sk = c_ret.c_customer_sk
JOIN web_page wp
    ON wp.wp_customer_sk = c_bill.c_customer_sk
JOIN date_dim d_wp_creation
    ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
JOIN date_dim d_wp_access
    ON wp.wp_access_date_sk = d_wp_access.d_date_sk
JOIN date_dim d_ws_open
    ON cs.cs_sold_date_sk = d_ws_open.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
GROUP BY
    cp.cp_department,
    sm.sm_type,
    d_sold.d_year
HAVING
    sum(cs.cs_net_profit) > 10000
ORDER BY
    total_net_paid DESC
LIMIT 100
