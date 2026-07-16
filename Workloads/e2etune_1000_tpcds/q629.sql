SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sm.sm_type,
    sm.sm_carrier,
    COUNT(*) AS num_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    SUM(wr.wr_fee) AS total_fee,
    SUM(wr.wr_return_ship_cost) AS total_ship_cost,
    (SUM(wr.wr_return_amt) - SUM(wr.wr_return_ship_cost)) AS net_return_amount
FROM income_band ib
JOIN web_returns wr
  ON wr.wr_return_amt BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
JOIN ship_mode sm
  ON (
        (wr.wr_return_ship_cost < 5 AND sm.sm_code = 'BIKE')
        OR (wr.wr_return_ship_cost >= 5 AND wr.wr_return_ship_cost < 15 AND sm.sm_code = 'AIR')
        OR (wr.wr_return_ship_cost >= 15 AND sm.sm_code = 'SURFACE')
     )
WHERE ib.ib_income_band_sk IN (1, 2, 3, 4, 5)
  AND wr.wr_return_quantity > 0
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound, sm.sm_type, sm.sm_carrier
HAVING COUNT(*) > 20
ORDER BY total_return_amount DESC
LIMIT 50
