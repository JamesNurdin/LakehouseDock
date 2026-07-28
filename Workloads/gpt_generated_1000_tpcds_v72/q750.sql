WITH filtered_sales AS (
    SELECT
        ss.ss_hdemo_sk,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        ib.ib_income_band_sk AS ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ss.ss_quantity > 10
      AND ss.ss_sales_price > 5.00
      AND hd.hd_vehicle_count >= 1
      AND hd.hd_dep_count <= 5
      AND ib.ib_lower_bound >= 10000
      AND ib.ib_upper_bound <= 200000
),
aggregated AS (
    SELECT
        ib_income_band_sk,
        hd_vehicle_count,
        hd_dep_count,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_hdemo_sk) AS distinct_households
    FROM filtered_sales f
    WHERE NOT EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_hdemo_sk = f.ss_hdemo_sk
          AND ss2.ss_quantity = 0
    )
    GROUP BY ROLLUP (ib_income_band_sk, hd_vehicle_count, hd_dep_count)
)
SELECT
    ib_income_band_sk,
    hd_vehicle_count,
    hd_dep_count,
    total_sales,
    total_profit,
    distinct_households,
    CASE
        WHEN total_profit > 100000 THEN 'HIGH'
        WHEN total_profit > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (PARTITION BY ib_income_band_sk ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY ib_income_band_sk,
         hd_vehicle_count NULLS LAST,
         hd_dep_count NULLS LAST
