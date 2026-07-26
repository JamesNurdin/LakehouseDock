WITH hour_stats AS (
    SELECT
        t.t_hour,
        SUM(ss.ss_ext_sales_price) AS hour_sales,
        SUM(ss.ss_net_profit) AS hour_profit,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        SUM(CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_customer_cnt,
        AVG(hd.hd_vehicle_count) AS avg_vehicle_count
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY t.t_hour
)
SELECT
    hs.t_hour,
    hs.hour_sales,
    hs.hour_profit,
    hs.avg_discount,
    hs.distinct_customers,
    hs.preferred_customer_cnt,
    hs.avg_vehicle_count,
    LAG(hs.hour_profit) OVER (ORDER BY hs.t_hour) AS prev_hour_profit,
    hs.hour_profit - LAG(hs.hour_profit) OVER (ORDER BY hs.t_hour) AS profit_delta,
    CASE
        WHEN hs.hour_profit > LAG(hs.hour_profit) OVER (ORDER BY hs.t_hour) THEN 'Increase'
        WHEN hs.hour_profit < LAG(hs.hour_profit) OVER (ORDER BY hs.t_hour) THEN 'Decrease'
        ELSE 'No Change'
    END AS profit_trend,
    RANK() OVER (ORDER BY hs.hour_profit DESC) AS profit_rank
FROM hour_stats hs
ORDER BY hs.t_hour
