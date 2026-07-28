WITH filtered_returns AS (
   SELECT
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk,
      sr.sr_item_sk,
      sr.sr_customer_sk,
      sr.sr_cdemo_sk,
      sr.sr_hdemo_sk,
      sr.sr_store_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_return_tax,
      sr.sr_net_loss,
      CASE
          WHEN sr.sr_return_amt > 100 THEN 'High'
          WHEN sr.sr_return_amt > 50 THEN 'Medium'
          ELSE 'Low'
      END AS return_category,
      (SELECT avg(sri.sr_return_amt) FROM store_returns sri) AS overall_avg_return_amt
   FROM store_returns sr
   WHERE sr.sr_return_amt > 20
     AND sr.sr_return_tax < 50
     AND sr.sr_return_quantity > 0
     AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2453000
   UNION ALL
   SELECT
      sr.sr_returned_date_sk,
      sr.sr_return_time_sk,
      sr.sr_item_sk,
      sr.sr_customer_sk,
      sr.sr_cdemo_sk,
      sr.sr_hdemo_sk,
      sr.sr_store_sk,
      sr.sr_return_quantity,
      sr.sr_return_amt,
      sr.sr_return_tax,
      sr.sr_net_loss,
      CASE
          WHEN sr.sr_return_amt > 100 THEN 'High'
          WHEN sr.sr_return_amt > 50 THEN 'Medium'
          ELSE 'Low'
      END AS return_category,
      (SELECT avg(sri.sr_return_amt) FROM store_returns sri) AS overall_avg_return_amt
   FROM store_returns sr
   WHERE sr.sr_return_amt > 20
     AND sr.sr_return_tax < 50
     AND sr.sr_return_quantity > 0
     AND sr.sr_hdemo_sk IN (
         SELECT hd.hd_demo_sk
         FROM household_demographics hd
         WHERE hd.hd_buy_potential IN ('0-500', '501-1000')
           AND hd.hd_dep_count >= 2
           AND hd.hd_vehicle_count <= 3
     )
     AND EXISTS (
         SELECT 1 FROM store_returns sr2
         WHERE sr2.sr_customer_sk = sr.sr_customer_sk
           AND sr2.sr_return_amt > 50
     )
)
SELECT
    fr.sr_returned_date_sk,
    fr.sr_return_time_sk,
    fr.sr_item_sk,
    fr.sr_customer_sk,
    hd.hd_buy_potential,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    fr.return_category,
    fr.sr_return_amt,
    fr.sr_net_loss,
    ROW_NUMBER() OVER (PARTITION BY hd.hd_buy_potential ORDER BY fr.sr_net_loss DESC) AS loss_rank,
    SUM(fr.sr_return_amt) OVER (PARTITION BY hd.hd_buy_potential ORDER BY fr.sr_returned_date_sk ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_sum_return_amt,
    AVG(fr.sr_return_amt) OVER (PARTITION BY hd.hd_buy_potential) AS avg_return_amt_by_potential,
    CASE
        WHEN fr.sr_return_amt > fr.overall_avg_return_amt THEN 1
        ELSE 0
    END AS above_avg_flag
FROM filtered_returns fr
INNER JOIN household_demographics hd
    ON fr.sr_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_income_band_sk IS NOT NULL
  AND hd.hd_buy_potential <> 'Unknown'
ORDER BY hd.hd_buy_potential, loss_rank
LIMIT 100
