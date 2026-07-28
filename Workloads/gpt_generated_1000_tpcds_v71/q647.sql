WITH sales_agg AS (
  SELECT
    s.s_store_id,
    s.s_zip,
    CASE WHEN hd.hd_vehicle_count >= 2 THEN 'HighVehicle' ELSE 'LowVehicle' END AS category,
    SUM(ss.ss_net_paid) AS total_amount
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE hd.hd_income_band_sk >= 10
    AND s.s_rec_end_date > DATE '2000-01-01'
  GROUP BY s.s_store_id,
           s.s_zip,
           CASE WHEN hd.hd_vehicle_count >= 2 THEN 'HighVehicle' ELSE 'LowVehicle' END
),
returns_agg AS (
  SELECT
    s.s_store_id,
    s.s_zip,
    CASE WHEN sr.sr_return_quantity > 1 THEN 'Multiple' ELSE 'Single' END AS category,
    SUM(sr.sr_return_amt) AS total_amount
  FROM store_returns sr
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  WHERE hd.hd_buy_potential = '5001-10000'
    AND s.s_zip LIKE '55%'
  GROUP BY s.s_store_id,
           s.s_zip,
           CASE WHEN sr.sr_return_quantity > 1 THEN 'Multiple' ELSE 'Single' END
)
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM returns_agg
ORDER BY total_amount DESC
LIMIT 100
