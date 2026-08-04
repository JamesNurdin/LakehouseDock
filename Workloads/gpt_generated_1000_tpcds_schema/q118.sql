WITH cs_agg AS (
    SELECT
        cs_call_center_sk,
        cs_sold_time_sk,
        cs_ship_mode_sk,
        cs_catalog_page_sk,
        cs_bill_cdemo_sk,
        cs_ship_cdemo_sk,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt
    FROM tpcds.catalog_sales TABLESAMPLE BERNOULLI (10)
    GROUP BY cs_call_center_sk, cs_sold_time_sk, cs_ship_mode_sk, cs_catalog_page_sk, cs_bill_cdemo_sk, cs_ship_cdemo_sk
)
SELECT
    cc.cc_name,
    cc.cc_state,
    u.loc AS location,
    td.t_hour,
    sm1.sm_carrier,
    cp.cp_department,
    cd_bill.cd_education_status,
    cd_ship.cd_marital_status,
    cc2.cc_manager,
    SUM(cs_agg.total_net_paid) AS agg_net_paid,
    SUM(cs_agg.total_quantity) AS agg_quantity,
    COUNT(DISTINCT sr.sr_ticket_number) AS return_ticket_cnt
FROM cs_agg
JOIN tpcds.call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.call_center cc2
    ON cs_agg.cs_call_center_sk = cc2.cc_call_center_sk
JOIN tpcds.time_dim td
    ON cs_agg.cs_sold_time_sk = td.t_time_sk
JOIN tpcds.time_dim td_dup
    ON cs_agg.cs_sold_time_sk = td_dup.t_time_sk
JOIN tpcds.ship_mode sm1
    ON cs_agg.cs_ship_mode_sk = sm1.sm_ship_mode_sk
JOIN tpcds.ship_mode sm2
    ON cs_agg.cs_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN tpcds.catalog_page cp
    ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.customer_demographics cd_bill
    ON cs_agg.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN tpcds.customer_demographics cd_ship
    ON cs_agg.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN tpcds.store_returns sr
    ON sr.sr_return_time_sk = td.t_time_sk
JOIN tpcds.time_dim td_ret
    ON sr.sr_return_time_sk = td_ret.t_time_sk
JOIN tpcds.customer_demographics cd_return
    ON sr.sr_cdemo_sk = cd_return.cd_demo_sk
CROSS JOIN UNNEST(ARRAY[cc.cc_state, cc.cc_country]) AS u(loc)
GROUP BY
    cc.cc_name,
    cc.cc_state,
    u.loc,
    td.t_hour,
    sm1.sm_carrier,
    cp.cp_department,
    cd_bill.cd_education_status,
    cd_ship.cd_marital_status,
    cc2.cc_manager
ORDER BY agg_net_paid DESC
