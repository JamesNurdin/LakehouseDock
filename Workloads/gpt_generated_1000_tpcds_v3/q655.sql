WITH sales_by_date AS (
    SELECT
        ss_sold_date_sk,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_quantity) AS total_quantity,
        COUNT(*) AS sales_txn_count
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450815 AND 2451074
    GROUP BY ss_sold_date_sk
),
returns_by_date AS (
    SELECT
        sr_returned_date_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(sr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS return_txn_count
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2450815 AND 2451074
    GROUP BY sr_returned_date_sk
)
SELECT
    d.d_year,
    CASE WHEN hd.hd_vehicle_count >= 2 THEN '2+ Vehicles' ELSE 'Fewer Vehicles' END AS vehicle_category,
    SUM(sbd.total_net_paid) AS total_sales,
    SUM(rbd.total_return_amt_inc_tax) AS total_returns,
    SUM(w.ws_net_paid_inc_tax) AS total_web_sales,
    SUM(i.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT cc.cc_call_center_id) AS call_center_count,
    AVG(w.ws_ext_ship_cost) AS avg_ship_cost
FROM sales_by_date sbd
JOIN date_dim d ON sbd.ss_sold_date_sk = d.d_date_sk
JOIN returns_by_date rbd ON rbd.sr_returned_date_sk = d.d_date_sk
JOIN web_sales w ON w.ws_sold_date_sk = d.d_date_sk
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN customer c ON c.c_first_sales_date_sk = d.d_date_sk
JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
JOIN ship_mode sm ON w.ws_ship_mode_sk = sm.sm_ship_mode_sk
WHERE
    d.d_year = 2001
    AND d.d_month_seq BETWEEN 1 AND 12
    AND cc.cc_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND i.inv_quantity_on_hand > 0
    AND c.c_preferred_cust_flag = 'Y'
GROUP BY
    d.d_year,
    CASE WHEN hd.hd_vehicle_count >= 2 THEN '2+ Vehicles' ELSE 'Fewer Vehicles' END
ORDER BY total_sales DESC
LIMIT 100
