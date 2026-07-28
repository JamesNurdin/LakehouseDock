WITH agg_sales AS (
    SELECT
        ss_hdemo_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(*) AS txn_count,
        AVG(ss_ext_sales_price) AS avg_sale
    FROM store_sales
    WHERE ss_ext_wholesale_cost > 500
      AND ss_list_price BETWEEN 50 AND 150
    GROUP BY ss_hdemo_sk
    HAVING SUM(ss_ext_sales_price) > 10000
)
SELECT
    hd.hd_demo_sk,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    agg.total_sales,
    agg.total_profit,
    CASE
        WHEN agg.total_profit / NULLIF(agg.total_sales, 0) > 0.2 THEN 'High Margin'
        WHEN agg.total_profit / NULLIF(agg.total_sales, 0) > 0.1 THEN 'Medium Margin'
        ELSE 'Low Margin'
    END AS profit_category,
    RANK() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY agg.total_sales DESC) AS sales_rank_income_band,
    (SELECT AVG(total_sales) FROM agg_sales) AS overall_avg_sales
FROM agg_sales agg
JOIN household_demographics hd ON agg.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_upper_bound <= 150000
  AND hd.hd_vehicle_count >= 0
  AND hd.hd_buy_potential <> 'Unknown'
ORDER BY ib.ib_income_band_sk, sales_rank_income_band
LIMIT 100
