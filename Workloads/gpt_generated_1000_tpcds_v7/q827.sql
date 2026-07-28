WITH sales_by_demo AS (
    SELECT
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        AVG(ss.ss_coupon_amt) AS avg_coupon
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_sold_time_sk BETWEEN 40000 AND 80000
        AND ss.ss_coupon_amt > 0
        AND ss.ss_ext_list_price > 1000
        AND hd.hd_dep_count >= 2
        AND hd.hd_vehicle_count <= 5
    GROUP BY hd.hd_income_band_sk, hd.hd_vehicle_count
)
SELECT
    income_band,
    AVG(total_profit) AS avg_profit_per_vehicle,
    SUM(total_sales) AS sum_sales_across_vehicles
FROM (
    SELECT
        hd_income_band_sk AS income_band,
        hd_vehicle_count,
        total_profit,
        total_sales
    FROM sales_by_demo
) sb
WHERE total_profit > 1000
GROUP BY income_band
HAVING AVG(total_profit) > 5000
ORDER BY avg_profit_per_vehicle DESC
LIMIT 10
