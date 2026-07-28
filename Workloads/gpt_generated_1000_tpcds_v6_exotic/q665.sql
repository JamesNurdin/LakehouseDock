WITH filtered_sales AS (
    SELECT
        ss.ss_hdemo_sk,
        ss.ss_quantity,
        ss.ss_wholesale_cost,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_ext_discount_amt,
        ss.ss_ext_tax,
        ss.ss_net_profit
    FROM store_sales ss
    WHERE ss.ss_wholesale_cost BETWEEN 25.00 AND 90.00
      AND ss.ss_quantity >= 1
      AND ss.ss_ext_discount_amt <= 2000.00
      AND ss.ss_ext_tax > 0
      AND ss.ss_net_paid > 0
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COUNT(DISTINCT fs.ss_hdemo_sk) AS distinct_households,
    SUM(fs.ss_ext_sales_price) AS total_sales,
    AVG(fs.ss_wholesale_cost) AS avg_wholesale_cost,
    MIN(fs.ss_net_profit) AS min_profit,
    MAX(fs.ss_net_profit) AS max_profit,
    ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY SUM(fs.ss_ext_sales_price) DESC) AS rank_by_sales
FROM filtered_sales fs
JOIN household_demographics hd
    ON fs.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_vehicle_count >= 0
  AND hd.hd_vehicle_count <= 2
  AND ib.ib_upper_bound >= 50000
  AND ib.ib_lower_bound <= 150000
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY total_sales DESC
LIMIT 100
