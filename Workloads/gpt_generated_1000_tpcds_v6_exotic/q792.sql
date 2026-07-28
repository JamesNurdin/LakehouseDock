WITH high_income AS (
   SELECT
       hd.hd_vehicle_count AS vehicle_count,
       SUM(sr.sr_refunded_cash) AS total_refunded,
       SUM(sr.sr_net_loss) AS total_loss
   FROM store_returns sr
   JOIN household_demographics hd
       ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
       ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE ib.ib_lower_bound >= 100000
     AND EXISTS (
         SELECT 1
         FROM store_returns sr2
         WHERE sr2.sr_hdemo_sk = sr.sr_hdemo_sk
           AND sr2.sr_return_quantity > 30
     )
   GROUP BY hd.hd_vehicle_count
),
low_income AS (
   SELECT
       hd.hd_vehicle_count AS vehicle_count,
       SUM(sr.sr_refunded_cash) AS total_refunded,
       SUM(sr.sr_net_loss) AS total_loss
   FROM store_returns sr
   JOIN household_demographics hd
       ON sr.sr_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
       ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE ib.ib_upper_bound < 100000
     AND sr.sr_return_quantity BETWEEN 10 AND 20
   GROUP BY hd.hd_vehicle_count
)
SELECT DISTINCT vehicle_count, total_refunded, total_loss
FROM (
    SELECT * FROM high_income
    UNION ALL
    SELECT * FROM low_income
) combined
ORDER BY total_refunded DESC
LIMIT 100
