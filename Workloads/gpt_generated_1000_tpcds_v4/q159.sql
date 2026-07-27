WITH sales_enriched AS (
    SELECT
        ss.ss_sold_time_sk,
        ss.ss_hdemo_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ext_tax,
        ss.ss_quantity,
        t.t_hour,
        t.t_minute,
        hd.hd_vehicle_count,
        hd.hd_income_band_sk,
        hd.hd_dep_count
    FROM store_sales ss
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND t.t_minute IN (1, 13, 17)
      AND hd.hd_income_band_sk >= 4
      AND hd.hd_vehicle_count >= 0
)
SELECT
    se.t_hour,
    se.hd_vehicle_count,
    COUNT(*) AS transaction_cnt,
    SUM(se.ss_ext_sales_price) AS total_sales,
    AVG(se.ss_net_profit) AS avg_net_profit,
    MIN(se.ss_ext_tax) AS min_tax,
    MAX(se.ss_ext_tax) AS max_tax
FROM sales_enriched se
GROUP BY se.t_hour, se.hd_vehicle_count
ORDER BY se.t_hour ASC, se.hd_vehicle_count DESC
LIMIT 100
