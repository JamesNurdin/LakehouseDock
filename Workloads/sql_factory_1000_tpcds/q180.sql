WITH sales_delay AS (
 SELECT cs.cs_order_number,
        sd.d_date AS sold_date,
        sh.d_date AS ship_date,
        DATE_DIFF('day', sd.d_date, sh.d_date) AS ship_delay_days,
        cs.cs_net_profit,
        sm.sm_type,
        sm.sm_carrier,
        t.t_hour
 FROM catalog_sales cs
 JOIN date_dim sd ON cs.cs_sold_date_sk = sd.d_date_sk
 JOIN date_dim sh ON cs.cs_ship_date_sk = sh.d_date_sk
 JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
 JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
)
SELECT sm_type,
       sm_carrier,
       ship_delay_days,
       cs_net_profit,
       AVG(ship_delay_days) OVER (PARTITION BY sm_type) AS avg_delay,
       approx_percentile(ship_delay_days, 0.5) OVER (PARTITION BY sm_type) AS median_delay,
       CASE WHEN ship_delay_days > AVG(ship_delay_days) OVER (PARTITION BY sm_type) THEN 'Longer than Avg' ELSE 'Shorter or Equal to Avg' END AS delay_category,
       RANK() OVER (PARTITION BY sm_type ORDER BY cs_net_profit DESC) AS profit_rank
FROM sales_delay
WHERE ship_delay_days IS NOT NULL
ORDER BY sm_type, profit_rank
LIMIT 20
