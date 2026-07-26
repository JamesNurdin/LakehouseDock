WITH hourly_agg AS (
 SELECT d.d_date,
        d.d_year,
        t.t_hour,
        sm.sm_type,
        SUM(cs.cs_net_paid) AS hour_net_paid,
        AVG(cs.cs_net_profit) AS avg_hour_profit
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
 JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
 WHERE sm.sm_type IN ('AIR', 'RAIL')
 GROUP BY d.d_date, d.d_year, t.t_hour, sm.sm_type
)
SELECT d_date,
       d_year,
       t_hour,
       sm_type,
       hour_net_paid,
       avg_hour_profit,
       SUM(hour_net_paid) OVER (PARTITION BY sm_type ORDER BY d_date, t_hour ROWS UNBOUNDED PRECEDING) AS cumulative_net_paid,
       ROW_NUMBER() OVER (PARTITION BY sm_type ORDER BY hour_net_paid DESC) AS profit_rank,
       CASE WHEN hour_net_paid = MAX(hour_net_paid) OVER (PARTITION BY sm_type) THEN 'Peak' ELSE 'Normal' END AS paid_status
FROM hourly_agg
WHERE d_year = 2001
ORDER BY sm_type, d_date, t_hour
