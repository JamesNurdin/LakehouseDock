WITH filtered_sales AS (
    SELECT
        cs_bill_hdemo_sk,
        cs_ext_wholesale_cost,
        cs_ext_list_price,
        cs_net_paid_inc_ship,
        cs_quantity,
        cs_order_number
    FROM catalog_sales
    WHERE cs_ext_wholesale_cost > 500
      AND cs_ext_wholesale_cost < 4000
      AND cs_quantity BETWEEN 1 AND 10
      AND cs_net_paid_inc_ship > 1000
)
SELECT
    f.cs_order_number,
    f.cs_quantity,
    f.cs_ext_wholesale_cost,
    f.cs_ext_list_price,
    f.cs_net_paid_inc_ship,
    hd.hd_demo_sk,
    hd.hd_vehicle_count,
    hd.hd_dep_count,
    CASE WHEN hd.hd_vehicle_count = 0 THEN 'NoVehicle' ELSE 'HasVehicle' END AS vehicle_flag,
    (
        SELECT avg(cs_ext_wholesale_cost)
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_hdemo_sk = hd.hd_demo_sk
    ) AS avg_wholesale_by_demo,
    RANK() OVER (
        PARTITION BY CASE WHEN hd.hd_vehicle_count = 0 THEN 'NoVehicle' ELSE 'HasVehicle' END
        ORDER BY f.cs_net_paid_inc_ship DESC
    ) AS revenue_rank,
    SUM(f.cs_net_paid_inc_ship) OVER (
        PARTITION BY hd.hd_demo_sk
        ORDER BY f.cs_order_number
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_sum_3_orders
FROM filtered_sales f
JOIN household_demographics hd
    ON f.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_vehicle_count >= 1
  AND hd.hd_dep_count <= 5
ORDER BY revenue_rank ASC, f.cs_net_paid_inc_ship DESC
LIMIT 100
