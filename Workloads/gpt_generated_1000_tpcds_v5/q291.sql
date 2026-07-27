WITH ship_demo_high AS (
    SELECT 
        sm.sm_ship_mode_id AS ship_mode_id,
        sm.sm_type AS ship_mode_type,
        'ShipDemoHighVehicle' AS segment,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid
    FROM tpcds.catalog_sales cs
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.household_demographics hd
        ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count > 2
    GROUP BY sm.sm_ship_mode_id, sm.sm_type
),
bill_demo_low AS (
    SELECT 
        sm.sm_ship_mode_id AS ship_mode_id,
        sm.sm_type AS ship_mode_type,
        'BillDemoLowVehicle' AS segment,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid
    FROM tpcds.catalog_sales cs
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_vehicle_count <= 1
    GROUP BY sm.sm_ship_mode_id, sm.sm_type
)
SELECT * FROM ship_demo_high
UNION ALL
SELECT * FROM bill_demo_low
ORDER BY total_net_paid DESC
LIMIT 100
