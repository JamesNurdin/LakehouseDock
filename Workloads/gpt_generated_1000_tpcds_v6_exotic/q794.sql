WITH sales_agg AS (
    SELECT
        ss_hdemo_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        AVG(ss_quantity) AS avg_quantity,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_ext_wholesale_cost BETWEEN 200.00 AND 5000.00
      AND ss_quantity > 0
    GROUP BY ss_hdemo_sk
),
eligible_income AS (
    SELECT *
    FROM income_band
    WHERE ib_upper_bound <= 180000
      AND ib_lower_bound >= 10000
)
SELECT
    hd.hd_buy_potential,
    ib.ib_upper_bound,
    SUM(sa.total_sales) AS sum_sales,
    AVG(sa.total_profit) AS avg_profit,
    COUNT(*) AS num_households,
    (SELECT AVG(total_sales) FROM sales_agg) AS overall_avg_sales
FROM sales_agg sa
JOIN household_demographics hd
  ON sa.ss_hdemo_sk = hd.hd_demo_sk
JOIN eligible_income ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_vehicle_count >= 0
  AND hd.hd_dep_count <= 5
  AND NOT EXISTS (
        SELECT 1
        FROM store_sales s2
        WHERE s2.ss_hdemo_sk = hd.hd_demo_sk
          AND s2.ss_ext_wholesale_cost > 5000
    )
GROUP BY ROLLUP (hd.hd_buy_potential, ib.ib_upper_bound)
HAVING SUM(sa.total_sales) > 20000
ORDER BY sum_sales DESC, hd.hd_buy_potential
LIMIT 100
