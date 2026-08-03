WITH hd_filtered AS (
   SELECT hd_demo_sk,
          hd_income_band_sk,
          hd_buy_potential,
          hd_dep_count,
          hd_vehicle_count
   FROM tpcds.household_demographics
   WHERE hd_income_band_sk IN (5, 9, 19)
     AND hd_dep_count >= 3
     AND hd_buy_potential = '1001-5000'
),
intersect_keys AS (
   SELECT hd_demo_sk FROM tpcds.household_demographics WHERE hd_vehicle_count > 2
   INTERSECT
   SELECT hd_demo_sk FROM tpcds.household_demographics WHERE hd_dep_count < 8
)
SELECT
   hd.hd_demo_sk,
   hd.hd_buy_potential,
   COUNT(wr.wr_order_number) AS return_cnt,
   SUM(wr.wr_return_amt) AS total_return_amt,
   AVG(wr.wr_return_amt) AS avg_return_amt,
   MAX(wr.wr_net_loss) AS max_net_loss,
   CASE
       WHEN wr.wr_return_amt > 500 THEN 'High'
       WHEN wr.wr_return_amt BETWEEN 100 AND 500 THEN 'Medium'
       ELSE 'Low'
   END AS return_amount_category,
   (
       SELECT AVG(wr2.wr_return_amt)
       FROM tpcds.web_returns wr2
       WHERE wr2.wr_return_quantity > 1
   ) AS avg_return_amt_qty_gt1
FROM tpcds.web_returns wr
RIGHT OUTER JOIN hd_filtered hd
   ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE wr.wr_return_amt IS NOT NULL
  AND wr.wr_return_tax < 50.00
  AND wr.wr_return_ship_cost BETWEEN 50.00 AND 500.00
  AND hd.hd_demo_sk IN (SELECT hd_demo_sk FROM intersect_keys)
GROUP BY
   hd.hd_demo_sk,
   hd.hd_buy_potential,
   CASE
       WHEN wr.wr_return_amt > 500 THEN 'High'
       WHEN wr.wr_return_amt BETWEEN 100 AND 500 THEN 'Medium'
       ELSE 'Low'
   END
ORDER BY total_return_amt DESC
LIMIT 100
