WITH sales_sample AS (
    SELECT
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        SUM(cs.cs_net_paid_inc_ship) AS total_paid,
        SUM(cs.cs_quantity) AS total_qty
    FROM tpcds.catalog_sales cs
    TABLESAMPLE BERNOULLI (10)
    GROUP BY
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk
)
SELECT
    cc.cc_name,
    cp.cp_department,
    sm.sm_code,
    CASE WHEN sm.sm_code = 'AIR' THEN 'Fast' ELSE 'Standard' END AS shipping_category,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ss.total_paid,
    ss.total_qty,
    w.w_warehouse_name,
    p.p_promo_name,
    td.t_hour,
    hd_bill.hd_vehicle_count AS bill_vehicle_count,
    hd_ship.hd_vehicle_count AS ship_vehicle_count,
    cr.cr_return_amount,
    wr.wr_return_amt,
    lc.total_return_qty,
    wp.wp_url
FROM sales_sample ss
JOIN tpcds.call_center cc
    ON ss.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.ship_mode sm
    ON ss.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w
    ON ss.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.promotion p
    ON ss.cs_promo_sk = p.p_promo_sk
JOIN tpcds.catalog_page cp
    ON ss.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.time_dim td
    ON ss.cs_sold_time_sk = td.t_time_sk
JOIN tpcds.household_demographics hd_bill
    ON ss.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.household_demographics hd_ship
    ON ss.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN tpcds.income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = ss.cs_order_number
    AND cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN tpcds.web_returns wr
    ON wr.wr_returned_time_sk = td.t_time_sk
    AND wr.wr_refunded_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN tpcds.web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
CROSS JOIN (SELECT DISTINCT sm_code FROM tpcds.ship_mode WHERE sm_code IN ('AIR','SEA')) AS sc
LEFT JOIN LATERAL (
    SELECT SUM(cr2.cr_return_quantity) AS total_return_qty
    FROM tpcds.catalog_returns cr2
    WHERE cr2.cr_order_number = ss.cs_order_number
) AS lc ON TRUE
LIMIT 100
