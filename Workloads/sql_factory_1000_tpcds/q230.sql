WITH hourly_agg AS (
 SELECT d.d_date,
        d.d_year,
        t.t_hour,
        sm.sm_type,
        SUM(cs.cs_net_paid) AS hour_net_paid,
        SUM(cs.cs_net_profit) AS hour_net_profit,
        COUNT(*) AS hour_txn_cnt
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
 JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
 WHERE d.d_year BETWEEN 2000 AND 2002
 GROUP BY d.d_date, d.d_year, t.t_hour, sm.sm_type
)
SELECT d_date,
       d_year,
       t_hour,
       sm_type,
       hour_net_paid,
       hour_net_profit,
       hour_txn_cnt,
       SUM(hour_net_paid) OVER (PARTITION BY sm_type ORDER BY d_date, t_hour ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7h_net_paid,
       LAG(hour_net_profit, 1) OVER (PARTITION BY sm_type ORDER BY d_date, t_hour) AS prev_hour_net_profit,
       CASE WHEN hour_net_profit > COALESCE(LAG(hour_net_profit) OVER (PARTITION BY sm_type ORDER BY d_date, t_hour), 0) THEN 'Profit Up' ELSE 'Profit Down' END AS profit_trend
FROM hourly_agg
WHERE d_year = 2001
ORDER BY sm_type, d_date, t_hour
