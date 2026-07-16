WITH brand_profit AS (
  SELECT
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    i.i_brand,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    SUM(ss.ss_quantity) AS total_quantity
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE hd.hd_dep_count = 2
    AND hd.hd_vehicle_count >= 1
    AND i.i_category = 'Electronics'
    AND ss.ss_quantity > 0
  GROUP BY ib.ib_lower_bound, ib.ib_upper_bound, i.i_brand
)
SELECT
  ib_lower_bound,
  ib_upper_bound,
  i_brand,
  total_profit,
  avg_discount,
  total_quantity,
  RANK() OVER (PARTITION BY ib_lower_bound, ib_upper_bound ORDER BY total_profit DESC) AS profit_rank
FROM brand_profit
WHERE total_profit > 5000
ORDER BY ib_lower_bound, profit_rank
LIMIT 50
