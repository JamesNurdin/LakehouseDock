WITH ws_pre AS (
    SELECT
        ws_sold_time_sk,
        ws_bill_hdemo_sk,
        ws_ship_hdemo_sk,
        ws_ship_mode_sk,
        ws_warehouse_sk,
        COUNT(DISTINCT ws_order_number) AS distinct_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        CASE
            WHEN SUM(ws_ext_sales_price) > 200000 THEN 'HIGH'
            WHEN SUM(ws_ext_sales_price) > 100000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS sales_band
    FROM web_sales
    WHERE ws_coupon_amt > 500
      AND ws_quantity >= 2
      AND ws_sales_price >= 50
      AND ws_ext_tax < 1000
    GROUP BY ws_sold_time_sk, ws_bill_hdemo_sk, ws_ship_hdemo_sk, ws_ship_mode_sk, ws_warehouse_sk
)
SELECT
    t.t_shift,
    hd_bill.hd_dep_count AS bill_dep_count,
    hd_ship.hd_vehicle_count AS ship_vehicle_count,
    sm.sm_carrier,
    w.w_city,
    ws_pre.sales_band,
    ws_pre.total_sales,
    ws_pre.distinct_orders,
    COUNT(DISTINCT ws_pre.ws_ship_mode_sk) AS distinct_ship_modes,
    COUNT(DISTINCT ws_pre.ws_warehouse_sk) AS distinct_warehouses,
    SUM(ws_pre.total_discount) AS sum_discount,
    u.key_val
FROM ws_pre
FULL OUTER JOIN time_dim t
    ON ws_pre.ws_sold_time_sk = t.t_time_sk
LEFT JOIN ship_mode sm
    ON ws_pre.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w
    ON ws_pre.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN household_demographics hd_bill
    ON ws_pre.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN household_demographics hd_ship
    ON ws_pre.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
CROSS JOIN UNNEST(ARRAY[ws_pre.ws_ship_mode_sk, ws_pre.ws_warehouse_sk]) AS u(key_val)
WHERE t.t_shift = 'first'
  AND sm.sm_contract LIKE 'A%'
  AND w.w_country = 'United States'
  AND hd_bill.hd_dep_count >= 2
GROUP BY
    t.t_shift,
    hd_bill.hd_dep_count,
    hd_ship.hd_vehicle_count,
    sm.sm_carrier,
    w.w_city,
    ws_pre.sales_band,
    ws_pre.total_sales,
    ws_pre.distinct_orders,
    u.key_val
ORDER BY ws_pre.total_sales DESC
LIMIT 100
