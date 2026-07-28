WITH sales_a AS (
    SELECT
        cc.cc_name,
        hd.hd_buy_potential,
        SUM(cs.cs_net_paid) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN customer cu
        ON cs.cs_bill_customer_sk = cu.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_rec_end_date = DATE '2000-12-31'
      AND cc.cc_state = 'CA'
      AND hd.hd_vehicle_count >= 2
      AND cu.c_last_review_date > 2452500
      AND cs.cs_net_profit > 0
    GROUP BY cc.cc_name, hd.hd_buy_potential
),
sales_b AS (
    SELECT
        cc.cc_name,
        hd.hd_buy_potential,
        SUM(cs.cs_net_paid) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN customer cu
        ON cs.cs_ship_customer_sk = cu.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_ship_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_rec_end_date = DATE '2001-12-31'
      AND cc.cc_state = 'TX'
      AND hd.hd_dep_count <= 3
      AND cu.c_last_review_date BETWEEN 2452300 AND 2452600
      AND cs.cs_net_profit > 10
    GROUP BY cc.cc_name, hd.hd_buy_potential
)
SELECT *
FROM (
    SELECT * FROM sales_a
    UNION ALL
    SELECT * FROM sales_b
) AS combined
ORDER BY total_sales DESC
LIMIT 100
