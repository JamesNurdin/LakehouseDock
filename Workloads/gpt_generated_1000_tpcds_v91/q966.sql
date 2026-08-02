WITH base1 AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_hdemo_sk ORDER BY ws.ws_ext_sales_price DESC) AS rn,
        CASE WHEN ws.ws_ext_sales_price > 10000 THEN 'HIGH' ELSE 'LOW' END AS price_category,
        ws.ws_sold_time_sk,
        ws.ws_sold_date_sk
    FROM web_sales ws
    INNER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    INNER JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    INNER JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    INNER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE sm.sm_type = 'EXPRESS'
      AND td.t_am_pm = 'PM'
      AND hd_bill.hd_vehicle_count >= 2
      AND EXISTS (
          SELECT 1
          FROM warehouse w
          WHERE w.w_warehouse_sk = ws.ws_warehouse_sk
            AND w.w_state = 'CA'
      )
),
base2 AS (
    SELECT
        ws.ws_order_number AS order_number,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_ship_hdemo_sk ORDER BY ws.ws_ext_sales_price DESC) AS rn,
        CASE WHEN ws.ws_ext_sales_price > 10000 THEN 'HIGH' ELSE 'LOW' END AS price_category,
        ws.ws_sold_time_sk,
        ws.ws_sold_date_sk
    FROM web_sales ws
    INNER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    INNER JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    INNER JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    INNER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE sm.sm_type = 'OVERNIGHT'
      AND td.t_am_pm = 'AM'
      AND hd_ship.hd_vehicle_count >= 2
      AND EXISTS (
          SELECT 1
          FROM warehouse w
          WHERE w.w_warehouse_sk = ws.ws_warehouse_sk
            AND w.w_state = 'TX'
      )
),
unioned AS (
    SELECT order_number, ws_ext_sales_price, rn, price_category
    FROM base1
    UNION
    SELECT order_number, ws_ext_sales_price, rn, price_category
    FROM base2
),
intersect_set AS (
    SELECT ws.ws_order_number AS order_number
    FROM web_sales ws
    INNER JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count > 1
      AND ws.ws_ext_sales_price > 5000
    INTERSECT
    SELECT ws.ws_order_number
    FROM web_sales ws
    INNER JOIN household_demographics hd ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count > 1
      AND ws.ws_ext_sales_price > 5000
)
SELECT
    u.order_number,
    u.ws_ext_sales_price,
    u.rn,
    u.price_category
FROM unioned u
WHERE u.order_number IN (SELECT order_number FROM intersect_set)
ORDER BY u.rn
LIMIT 100
