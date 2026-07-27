WITH per_demo AS (
  SELECT
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    hd.hd_vehicle_count,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
    SUM(ws.ws_net_paid_inc_tax) AS total_sales_amt,
    COUNT(*) AS txn_cnt
  FROM store_returns sr
  JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN web_sales ws
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  WHERE sr.sr_return_amt_inc_tax > 100
    AND hd.hd_vehicle_count >= 0
    AND hd.hd_buy_potential = '1001-5000'
    AND ws.ws_web_site_sk IN (28, 47)
    AND ws.ws_sold_time_sk BETWEEN 40000 AND 80000
  GROUP BY hd.hd_demo_sk, hd.hd_buy_potential, hd.hd_vehicle_count
)
SELECT
  pd.hd_vehicle_count,
  AVG(pd.total_return_amt) AS avg_return_amt,
  AVG(pd.total_sales_amt) AS avg_sales_amt,
  SUM(pd.txn_cnt) AS total_txns
FROM per_demo pd
WHERE pd.total_return_amt > 200
GROUP BY pd.hd_vehicle_count
HAVING AVG(pd.total_sales_amt) > 500
ORDER BY avg_return_amt DESC
LIMIT 100
