WITH hourly_agg AS (
 SELECT d.d_date,
        d.d_year,
        t.t_hour,
        sm.sm_type,
        SUM(cs.cs_net_paid) AS hour_net_paid,
        SUM(cs.cs_net_profit) AS hour_net_profit,
        SUM(cs.cs_ext_discount_amt) AS hour_discount
 FROM catalog_sales cs
 JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
 JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
 JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
 GROUP BY d.d_date, d.d_year, t.t_hour, sm.sm_type
)
SELECT d_date,
       d_year,
       t_hour,
       sm_type,
       hour_net_paid,
       hour_net_profit,
       hour_discount,
       SUM(hour_discount) OVER (PARTITION BY sm_type ORDER BY d_date, t_hour ROWS UNBOUNDED PRECEDING) AS cumulative_discount,
       PERCENT_RANK() OVER (PARTITION BY sm_type ORDER BY hour_net_paid) AS net_paid_percentile,
       CASE WHEN hour_discount > 0 THEN 'Discounted' ELSE 'Full Price' END AS discount_flag
FROM hourly_agg
WHERE d_year = 2001 AND hour_discount > 0
ORDER BY sm_type, d_date, t_hour
