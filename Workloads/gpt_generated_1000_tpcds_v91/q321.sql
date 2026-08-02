WITH intersect_orders AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_quantity > 5
    INTERSECT
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_ext_sales_price > 100
),

sales_per_order AS (
    SELECT
        ws.ws_order_number,
        hd.hd_buy_potential,
        sm.sm_code,
        ib.ib_upper_bound,
        hd.hd_vehicle_count,
        CASE WHEN hd.hd_vehicle_count > 2 THEN 'High' ELSE 'Low' END AS veh_category,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE hd.hd_vehicle_count <> -1
      AND hd.hd_dep_count >= 2
      AND hd.hd_buy_potential LIKE '5%-%'
      AND sm.sm_code IN ('AIR', 'SURFACE')
      AND sm.sm_contract <> 'OrDuVy2H'
      AND ib.ib_upper_bound >= 100000
      AND ws.ws_order_number IN (SELECT ws_order_number FROM intersect_orders)
),

order_agg AS (
    SELECT
        veh_category,
        sm_code,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_profit,
        SUM(ws_quantity) AS total_qty,
        COUNT(*) AS order_cnt
    FROM sales_per_order
    GROUP BY veh_category, sm_code
)
SELECT
    oa.veh_category,
    oa.sm_code,
    oa.total_sales,
    oa.avg_profit,
    oa.total_qty,
    oa.order_cnt,
    CASE WHEN oa.total_sales > 100000 THEN 'Big' ELSE 'Small' END AS sales_size,
    (SELECT MAX(o2.total_sales) FROM order_agg o2 WHERE o2.veh_category = oa.veh_category) AS max_sales_in_veh_category,
    (SELECT COUNT(*) FROM order_agg o3 WHERE o3.sm_code = oa.sm_code AND o3.total_sales > oa.total_sales) AS higher_sales_same_code
FROM order_agg oa
WHERE oa.total_sales > (
    SELECT AVG(o4.total_sales) FROM order_agg o4 WHERE o4.sm_code = oa.sm_code
)
ORDER BY oa.total_sales DESC, oa.veh_category
