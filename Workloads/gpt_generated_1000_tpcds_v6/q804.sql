WITH filtered_sales AS (
    SELECT
        cs.cs_ship_mode_sk,
        cs.cs_sold_time_sk,
        cs.cs_net_paid_inc_ship,
        cs.cs_ext_ship_cost,
        cs.cs_quantity,
        cs.cs_net_profit,
        sm.sm_code,
        sm.sm_contract,
        t.t_meal_time,
        t.t_hour,
        c.c_customer_sk
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_net_paid_inc_ship >= 500
      AND cs.cs_ext_ship_cost BETWEEN 100 AND 2000
      AND cs.cs_quantity >= 2
      AND sm.sm_code = 'AIR'
      AND sm.sm_contract = 'A5BYO1qH8HGTTN'
      AND t.t_meal_time = 'lunch'
)
SELECT
    sm_code,
    t_meal_time,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers,
    SUM(cs_quantity) AS total_quantity,
    SUM(cs_net_paid_inc_ship) AS total_paid_inc_ship,
    AVG(cs_net_profit) AS avg_profit,
    CASE
        WHEN SUM(cs_net_profit) > 0 THEN 'profitable'
        ELSE 'loss'
    END AS profit_status
FROM filtered_sales
GROUP BY sm_code, t_meal_time
ORDER BY total_paid_inc_ship DESC
LIMIT 100
