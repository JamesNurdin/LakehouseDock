WITH union_sales AS (
    -- First segment: high income band customers in California
    SELECT
        w.w_warehouse_name AS warehouse_name,
        cd.cd_gender AS gender,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
        CASE WHEN SUM(cs.cs_net_paid) > 10000 THEN 'High' ELSE 'Low' END AS revenue_category
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk > 10                     -- predicate 1
      AND w.w_state = 'CA'                               -- predicate 2
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2451000 -- predicate 3
    GROUP BY w.w_warehouse_name, cd.cd_gender

    UNION DISTINCT

    -- Second segment: low income band customers in Texas
    SELECT
        w.w_warehouse_name,
        cd.cd_gender,
        SUM(cs.cs_net_paid),
        COUNT(DISTINCT cs.cs_order_number),
        CASE WHEN SUM(cs.cs_net_paid) > 10000 THEN 'High' ELSE 'Low' END
    FROM catalog_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk <= 10
      AND w.w_state = 'TX'
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2451000
    GROUP BY w.w_warehouse_name, cd.cd_gender
),
aggregated AS (
    SELECT
        warehouse_name,
        gender,
        SUM(total_net_paid) AS total_net_paid,
        SUM(orders_cnt) AS total_orders,
        CASE WHEN SUM(total_net_paid) > 50000 THEN 'Very High' ELSE 'Normal' END AS overall_category
    FROM union_sales
    GROUP BY ROLLUP (warehouse_name, gender)
)
SELECT
    warehouse_name,
    gender,
    total_net_paid,
    total_orders,
    overall_category,
    rn
FROM (
    SELECT
        COALESCE(warehouse_name, 'ALL_WAREHOUSES') AS warehouse_name,
        COALESCE(gender, 'ALL_GENDERS') AS gender,
        total_net_paid,
        total_orders,
        overall_category,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(warehouse_name, 'ALL_WAREHOUSES')
                           ORDER BY total_net_paid DESC) AS rn
    FROM aggregated
) t
WHERE rn <= 5
ORDER BY warehouse_name, gender
LIMIT 100
