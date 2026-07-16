WITH profit_by_hour_income AS (
    SELECT
        td.t_hour,
        hd.hd_income_band_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE td.t_hour BETWEEN 8 AND 20
      AND hd.hd_vehicle_count >= 2
    GROUP BY td.t_hour, hd.hd_income_band_sk
)
SELECT
    t_hour,
    hd_income_band_sk,
    total_net_profit,
    total_sales,
    sales_cnt,
    total_net_profit / NULLIF(total_sales, 0) AS profit_margin,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM profit_by_hour_income
WHERE total_net_profit > 1000
ORDER BY profit_margin DESC
LIMIT 10
