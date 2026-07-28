WITH filtered AS (
   SELECT
       ca.ca_address_sk,
       ca.ca_state,
       ca.ca_gmt_offset,
       ca.ca_county,
       hd.hd_income_band_sk,
       hd.hd_vehicle_count,
       wr.wr_return_amt,
       wr.wr_net_loss
   FROM web_returns wr
   JOIN household_demographics hd
       ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   JOIN customer_address ca
       ON wr.wr_refunded_addr_sk = ca.ca_address_sk
   WHERE ca.ca_gmt_offset = -5.00
     AND hd.hd_vehicle_count >= 0
     AND wr.wr_return_amt > 100.00
     AND ca.ca_address_sk IN (
         SELECT wr_refunded_addr_sk
         FROM web_returns
         WHERE wr_return_amt > 2000.00
     )
)
SELECT
   ca_state,
   ca_county,
   hd_income_band_sk,
   SUM(wr_return_amt) AS total_return_amt,
   SUM(wr_net_loss) AS total_net_loss,
   CASE WHEN SUM(wr_return_amt) > 5000 THEN 'HIGH' ELSE 'LOW' END AS return_level,
   RANK() OVER (PARTITION BY ca_state ORDER BY SUM(wr_return_amt) DESC) AS state_rank,
   SUM(SUM(wr_return_amt)) OVER (
       PARTITION BY ca_state
       ORDER BY SUM(wr_return_amt)
       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
   ) AS cum_state_return
FROM filtered
GROUP BY ca_state, ca_county, hd_income_band_sk
ORDER BY total_return_amt DESC
LIMIT 100
