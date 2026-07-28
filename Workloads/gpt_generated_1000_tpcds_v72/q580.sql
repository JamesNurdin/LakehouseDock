WITH morning_sales AS (
    SELECT
        p.p_promo_id,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        'morning' AS period
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_sub_shift = 'morning'
      AND c.c_salutation = 'Mr.'
      AND hd.hd_vehicle_count > 0
    GROUP BY p.p_promo_id
),

evening_sales AS (
    SELECT
        p.p_promo_id,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        'evening' AS period
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_sub_shift = 'evening'
      AND c.c_salutation = 'Ms.'
      AND hd.hd_vehicle_count >= 1
    GROUP BY p.p_promo_id
),

combined AS (
    SELECT * FROM morning_sales
    UNION ALL
    SELECT * FROM evening_sales
)
SELECT
    p_promo_id,
    period,
    total_net_paid,
    orders,
    RANK() OVER (PARTITION BY period ORDER BY total_net_paid DESC) AS sales_rank
FROM combined
ORDER BY period, sales_rank
LIMIT 100
