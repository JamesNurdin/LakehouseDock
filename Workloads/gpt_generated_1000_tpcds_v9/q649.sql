SELECT
    ds_sold.d_year AS year,
    ds_sold.d_moy AS month,
    cc.cc_name AS call_center_name,
    ib.ib_lower_bound AS income_lower,
    ib.ib_upper_bound AS income_upper,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT cust_sales.c_customer_id) AS distinct_customers
FROM store_sales AS ss
JOIN date_dim AS ds_sold
    ON ss.ss_sold_date_sk = ds_sold.d_date_sk
JOIN customer AS cust_sales
    ON ss.ss_customer_sk = cust_sales.c_customer_sk
JOIN household_demographics AS hd_sales
    ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN income_band AS ib
    ON hd_sales.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns AS sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN date_dim AS ds_return
    ON sr.sr_returned_date_sk = ds_return.d_date_sk
JOIN catalog_sales AS cs
    ON cs.cs_sold_date_sk = ds_sold.d_date_sk
JOIN date_dim AS ds_cs_ship
    ON cs.cs_ship_date_sk = ds_cs_ship.d_date_sk
JOIN call_center AS cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim AS ds_cc_open
    ON cc.cc_open_date_sk = ds_cc_open.d_date_sk
JOIN date_dim AS ds_cc_closed
    ON cc.cc_closed_date_sk = ds_cc_closed.d_date_sk
JOIN catalog_page AS cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim AS ds_cp_start
    ON cp.cp_start_date_sk = ds_cp_start.d_date_sk
JOIN date_dim AS ds_cp_end
    ON cp.cp_end_date_sk = ds_cp_end.d_date_sk
JOIN web_page AS wp
    ON wp.wp_customer_sk = cust_sales.c_customer_sk
JOIN date_dim AS ds_wp_creation
    ON wp.wp_creation_date_sk = ds_wp_creation.d_date_sk
JOIN date_dim AS ds_wp_access
    ON wp.wp_access_date_sk = ds_wp_access.d_date_sk
JOIN customer AS cust_bill
    ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer AS cust_ship
    ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN household_demographics AS hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics AS hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
GROUP BY
    ds_sold.d_year,
    ds_sold.d_moy,
    cc.cc_name,
    ib.ib_lower_bound,
    ib.ib_upper_bound
ORDER BY
    ds_sold.d_year DESC,
    total_catalog_sales DESC
LIMIT 100
