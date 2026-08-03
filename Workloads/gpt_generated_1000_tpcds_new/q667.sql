WITH
  aggregated_sales AS (
    SELECT
      ss_hdemo_sk,
      SUM(ss_net_paid)               AS total_net_paid,
      SUM(ss_ext_tax)                AS total_tax,
      COUNT(*)                       AS sales_cnt,
      AVG(ss_list_price)             AS avg_list_price
    FROM store_sales
    WHERE ss_ext_tax                > 10
      AND ss_list_price            BETWEEN 20 AND 120
      AND ss_quantity              > 0
      AND ss_net_paid              IS NOT NULL
      AND ss_wholesale_cost        < ss_list_price
      AND ss_ext_discount_amt     >= 0
    GROUP BY ss_hdemo_sk
  ),
  hd_ib AS (
    SELECT
      hd.hd_demo_sk,
      hd.hd_income_band_sk,
      hd.hd_buy_potential,
      hd.hd_dep_count,
      hd.hd_vehicle_count,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      ib.ib_income_band_sk
    FROM household_demographics hd
    FULL OUTER JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
  )
SELECT
  hd_ib.hd_demo_sk,
  hd_ib.hd_buy_potential,
  hd_ib.hd_dep_count,
  hd_ib.hd_vehicle_count,
  hd_ib.ib_lower_bound,
  hd_ib.ib_upper_bound,
  agg.total_net_paid,
  agg.total_tax,
  agg.sales_cnt,
  agg.avg_list_price,
  CASE
    WHEN hd_ib.hd_vehicle_count >= 3 THEN 'HighVehicle'
    WHEN hd_ib.hd_vehicle_count = 2 THEN 'MediumVehicle'
    ELSE 'LowVehicle'
  END AS vehicle_category,
  RANK() OVER (PARTITION BY hd_ib.ib_income_band_sk ORDER BY agg.total_net_paid DESC) AS rank_within_band
FROM hd_ib
JOIN aggregated_sales agg
  ON hd_ib.hd_demo_sk = agg.ss_hdemo_sk
WHERE hd_ib.hd_demo_sk NOT IN (
        SELECT ss_hdemo_sk FROM store_sales WHERE ss_quantity = 0
      )
  AND hd_ib.hd_dep_count      BETWEEN 2 AND 8
  AND hd_ib.hd_vehicle_count  IN (1, 2, 3, 4)
  AND hd_ib.ib_upper_bound   <= 90000
  AND agg.total_net_paid      > 1000
  AND agg.total_tax           > 50
  AND agg.avg_list_price      > 30
ORDER BY rank_within_band ASC, agg.total_net_paid DESC
OFFSET 0 LIMIT 100
