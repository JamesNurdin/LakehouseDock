WITH joined_data AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        c.c_customer_id,
        c.c_email_address,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sm.sm_ship_mode_id,
        sm.sm_code,
        sm.sm_contract,
        w.w_warehouse_id,
        w.w_zip,
        w.w_city,
        CASE
            WHEN cs.cs_net_profit > 10000 THEN 'HIGH'
            WHEN cs.cs_net_profit > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_tier
    FROM call_center cc
    FULL OUTER JOIN catalog_sales cs
        ON cc.cc_call_center_sk = cs.cs_call_center_sk
    LEFT JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE
        w.w_zip IN ('58828', '64593', '42477')
        AND sm.sm_code IN ('AIR', 'SEA')
        AND sm.sm_contract LIKE 'A%'
        AND ib.ib_lower_bound >= 50000
        AND cc.cc_state = 'TX'
        AND cs.cs_quantity >= 5
        AND cs.cs_net_profit > 0
),
agg_by_warehouse AS (
    SELECT
        w_warehouse_id,
        profit_tier,
        COUNT(DISTINCT cs_order_number) AS num_orders,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_net_profit) AS total_net_profit,
        AVG(cs_quantity) AS avg_quantity
    FROM joined_data
    GROUP BY w_warehouse_id, profit_tier
)
SELECT
    profit_tier,
    COUNT(*) AS num_warehouses,
    AVG(total_net_paid) AS avg_total_net_paid,
    AVG(total_net_profit) AS avg_total_net_profit,
    SUM(num_orders) AS total_orders_across_warehouses
FROM agg_by_warehouse
WHERE total_net_paid > 10000
GROUP BY profit_tier
ORDER BY avg_total_net_paid DESC
LIMIT 100
