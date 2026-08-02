WITH combined AS (
    SELECT
        wh.w_warehouse_sk,
        wh.w_warehouse_id,
        wh.w_city,
        wh.w_county,
        sm.sm_carrier,
        sm.sm_contract,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ws.ws_net_paid_inc_ship) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(*) AS order_count
    FROM web_sales ws
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    WHERE sm.sm_carrier IN ('DHL', 'LATVIAN')
      AND sm.sm_contract LIKE 'A%'
      AND wh.w_county = 'Richland County'
      AND hd.hd_vehicle_count >= 2
      AND ws.ws_net_paid_inc_ship > 1000
    GROUP BY
        wh.w_warehouse_sk,
        wh.w_warehouse_id,
        wh.w_city,
        wh.w_county,
        sm.sm_carrier,
        sm.sm_contract,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    UNION ALL
    SELECT
        wh.w_warehouse_sk,
        wh.w_warehouse_id,
        wh.w_city,
        wh.w_county,
        sm.sm_carrier,
        sm.sm_contract,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ws.ws_net_paid_inc_ship) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(*) AS order_count
    FROM web_sales ws
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
    WHERE sm.sm_carrier = 'ALLIANCE'
      AND sm.sm_contract = 'HVDFCcQ'
      AND wh.w_suite_number = 'Suite 0'
      AND hd.hd_buy_potential = '501-1000'
      AND ws.ws_quantity <= 2
    GROUP BY
        wh.w_warehouse_sk,
        wh.w_warehouse_id,
        wh.w_city,
        wh.w_county,
        sm.sm_carrier,
        sm.sm_contract,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    combined.w_warehouse_id,
    combined.w_city,
    combined.w_county,
    combined.sm_carrier,
    combined.sm_contract,
    combined.hd_buy_potential,
    combined.ib_lower_bound,
    combined.ib_upper_bound,
    combined.total_sales,
    combined.total_quantity,
    combined.order_count,
    RANK() OVER (PARTITION BY combined.w_warehouse_id ORDER BY combined.total_sales DESC) AS sales_rank,
    CASE
        WHEN combined.total_sales > 5000 THEN 'High'
        WHEN combined.total_sales > 2000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    (
        SELECT SUM(ws2.ws_net_paid_inc_ship)
        FROM web_sales ws2
        WHERE ws2.ws_warehouse_sk = combined.w_warehouse_sk
    ) AS warehouse_total_inc_ship
FROM combined
ORDER BY combined.total_sales DESC
LIMIT 100
