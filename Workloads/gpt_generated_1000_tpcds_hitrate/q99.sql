WITH catalog_agg AS (
   SELECT
       cs.cs_bill_customer_sk AS customer_id,
       SUM(cs.cs_net_profit) AS total_profit,
       'catalog' AS source
   FROM catalog_sales cs
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE hd.hd_vehicle_count >= 2
     AND ib.ib_upper_bound <= 5000
   GROUP BY cs.cs_bill_customer_sk
),
store_agg AS (
   SELECT
       ss.ss_customer_sk AS customer_id,
       SUM(ss.ss_net_profit) AS total_profit,
       'store' AS source
   FROM store_sales ss
   JOIN household_demographics hd
     ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE hd.hd_vehicle_count >= 2
     AND ib.ib_upper_bound <= 5000
   GROUP BY ss.ss_customer_sk
)
SELECT DISTINCT *
FROM (
   SELECT * FROM catalog_agg
   UNION ALL
   SELECT * FROM store_agg
) combined
ORDER BY total_profit DESC
LIMIT 100
