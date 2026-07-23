/*
Goal: Analyze total catalog sales performance by call center, catalog page, and month, enriched with store sales and web returns activity, while incorporating customer demographics and shipping information.
*/
WITH cs_agg AS (
    SELECT
        cs.cs_catalog_page_sk,
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        SUM(cs.cs_ext_sales_price) AS total_ext_sales_price,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_discount_amt) AS total_ext_discount_amt,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM tpcds.catalog_sales cs
    GROUP BY
        cs.cs_catalog_page_sk,
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk
)
SELECT
    cc.cc_name,
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    d_sold.d_year,
    d_sold.d_month_seq,
    sm.sm_carrier,
    SUM(ca.total_ext_sales_price) AS total_sales_price,
    SUM(ca.total_net_profit) AS total_net_profit,
    SUM(ca.total_ext_discount_amt) AS total_discount_amount,
    SUM(ca.distinct_orders) AS total_distinct_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_return_orders,
    COUNT(DISTINCT cd_bill.cd_gender) AS distinct_bill_genders,
    (SELECT COUNT(*)
       FROM tpcds.store_sales ss2
      WHERE ss2.ss_sold_date_sk = d_sold.d_date_sk) AS store_sales_count_for_date,
    (SELECT COUNT(*) FROM tpcds.ship_mode) AS total_ship_modes
FROM cs_agg ca
JOIN tpcds.catalog_page cp
    ON ca.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.call_center cc
    ON ca.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.ship_mode sm
    ON ca.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.date_dim d_sold
    ON ca.cs_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN tpcds.date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN tpcds.date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
JOIN tpcds.date_dim d_cc_closed
    ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
JOIN tpcds.customer_demographics cd_bill
    ON ca.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN tpcds.customer_demographics cd_ship
    ON ca.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN tpcds.store_sales ss
    ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.time_dim t_store
    ON ss.ss_sold_time_sk = t_store.t_time_sk
JOIN tpcds.customer_demographics cd_store
    ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
JOIN tpcds.web_returns wr
    ON wr.wr_returned_date_sk = d_sold.d_date_sk
JOIN tpcds.time_dim t_return
    ON wr.wr_returned_time_sk = t_return.t_time_sk
JOIN tpcds.customer_demographics cd_returning
    ON wr.wr_returning_cdemo_sk = cd_returning.cd_demo_sk
WHERE EXISTS (
    SELECT 1
      FROM tpcds.catalog_sales cs2
     WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk
       AND cs2.cs_sold_date_sk = d_sold.d_date_sk
)
GROUP BY
    cc.cc_name,
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    d_sold.d_year,
    d_sold.d_month_seq,
    sm.sm_carrier,
    d_sold.d_date_sk
ORDER BY
    total_sales_price DESC
LIMIT 100
