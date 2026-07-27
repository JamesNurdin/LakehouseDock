WITH cs_agg AS (
    SELECT
        cs_warehouse_sk,
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_bill_hdemo_sk,
        cs_ship_hdemo_sk,
        SUM(cs_ext_sales_price)            AS total_sales,
        SUM(cs_net_profit)                AS total_profit,
        COUNT(DISTINCT cs_order_number)   AS orders_cnt
    FROM tpcds.catalog_sales
    WHERE cs_ext_sales_price > 1000
    GROUP BY
        cs_warehouse_sk,
        cs_call_center_sk,
        cs_catalog_page_sk,
        cs_bill_hdemo_sk,
        cs_ship_hdemo_sk
)
SELECT
    cc.cc_name                                 AS call_center_name,
    w.w_warehouse_name                         AS warehouse_name,
    w_alt.w_warehouse_name                     AS alt_warehouse_name,
    cp.cp_department                           AS catalog_department,
    cp_alt.cp_type                              AS alt_page_type,
    hd_bill.hd_buy_potential                   AS billing_buy_potential,
    hd_ship.hd_vehicle_count                   AS shipping_vehicle_count,
    cs_agg.total_sales,
    cs_agg.total_profit,
    cs_agg.orders_cnt,
    (
        SELECT COUNT(*)
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk
    )                                           AS warehouse_sales_transactions
FROM cs_agg
JOIN tpcds.call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.call_center cc_alt
    ON cs_agg.cs_call_center_sk = cc_alt.cc_call_center_sk
JOIN tpcds.warehouse w
    ON cs_agg.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.warehouse w_alt
    ON cs_agg.cs_warehouse_sk = w_alt.w_warehouse_sk
JOIN tpcds.warehouse w_third
    ON cs_agg.cs_warehouse_sk = w_third.w_warehouse_sk
JOIN tpcds.catalog_page cp
    ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.catalog_page cp_alt
    ON cs_agg.cs_catalog_page_sk = cp_alt.cp_catalog_page_sk
JOIN tpcds.catalog_page cp_third
    ON cs_agg.cs_catalog_page_sk = cp_third.cp_catalog_page_sk
JOIN tpcds.household_demographics hd_bill
    ON cs_agg.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.household_demographics hd_ship
    ON cs_agg.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM tpcds.warehouse w_check
    WHERE w_check.w_state = 'NM'
      AND w_check.w_warehouse_sk = w.w_warehouse_sk
)
GROUP BY
    cc.cc_name,
    w.w_warehouse_name,
    w_alt.w_warehouse_name,
    cp.cp_department,
    cp_alt.cp_type,
    hd_bill.hd_buy_potential,
    hd_ship.hd_vehicle_count,
    cs_agg.total_sales,
    cs_agg.total_profit,
    cs_agg.orders_cnt,
    w.w_warehouse_sk
HAVING
    total_sales > 50000
    AND total_profit > 10000
ORDER BY
    total_sales DESC
LIMIT 100
