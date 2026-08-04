WITH sales_agg AS (
    SELECT ss_hdemo_sk,
           SUM(ss_ext_sales_price) AS total_sales,
           AVG(ss_ext_discount_amt) AS avg_discount,
           COUNT(*) AS sales_cnt,
           MIN(ss_net_paid) AS min_paid,
           MAX(ss_net_paid) AS max_paid
    FROM store_sales
    WHERE ss_ext_sales_price > 5000
      AND ss_quantity > 0
    GROUP BY ss_hdemo_sk
)
SELECT hd.hd_buy_potential,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       sa.total_sales,
       sa.avg_discount,
       sa.sales_cnt,
       sa.min_paid,
       sa.max_paid
FROM sales_agg sa
JOIN household_demographics hd
  ON sa.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE hd.hd_vehicle_count >= 2
  AND hd.hd_dep_count <= 5
  AND ib.ib_upper_bound <= 150000
  AND NOT EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_hdemo_sk = sa.ss_hdemo_sk
          AND ss2.ss_net_paid > 1000
    )
ORDER BY sa.total_sales DESC
LIMIT 100
