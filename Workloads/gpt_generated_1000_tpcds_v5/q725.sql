WITH hd_income AS (
    SELECT
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM household_demographics hd
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    warehouse_name,
    ship_type,
    gender_label,
    total_sales,
    order_cnt
FROM (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        sm.sm_type AS ship_type,
        CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_label,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN hd_income hi
        ON ws.ws_bill_hdemo_sk = hi.hd_demo_sk
    WHERE sm.sm_carrier = 'UPS'
      AND cd.cd_gender = 'M'
      AND hi.ib_upper_bound >= 120000
    GROUP BY w.w_warehouse_name, sm.sm_type, cd.cd_gender

    UNION ALL

    SELECT
        w.w_warehouse_name AS warehouse_name,
        sm.sm_type AS ship_type,
        CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_label,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN hd_income hi
        ON ws.ws_bill_hdemo_sk = hi.hd_demo_sk
    WHERE sm.sm_carrier = 'FedEx'
      AND cd.cd_gender = 'F'
      AND hi.ib_lower_bound <= 50000
    GROUP BY w.w_warehouse_name, sm.sm_type, cd.cd_gender
) AS combined
ORDER BY total_sales DESC
LIMIT 100
