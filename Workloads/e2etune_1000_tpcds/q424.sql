SELECT
    hd_ret.hd_vehicle_count AS returning_vehicle_count,
    hd_ret.hd_buy_potential AS returning_buy_potential,
    hd_ref.hd_vehicle_count AS refunded_vehicle_count,
    hd_ref.hd_buy_potential AS refunded_buy_potential,
    COUNT(*) AS num_returns,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_amt) AS avg_return_amount,
    SUM(wr.wr_return_quantity) AS total_quantity,
    SUM(wr.wr_return_amt) / NULLIF(SUM(wr.wr_return_quantity), 0) AS avg_amount_per_item
FROM web_returns wr
JOIN household_demographics hd_ret
  ON wr.wr_returning_hdemo_sk = hd_ret.hd_demo_sk
JOIN household_demographics hd_ref
  ON wr.wr_refunded_hdemo_sk = hd_ref.hd_demo_sk
WHERE hd_ret.hd_income_band_sk BETWEEN 3 AND 5
  AND hd_ref.hd_income_band_sk BETWEEN 3 AND 5
  AND wr.wr_net_loss > 0
  AND wr.wr_return_quantity > 0
  AND hd_ret.hd_buy_potential = '>10000'
GROUP BY
    hd_ret.hd_vehicle_count,
    hd_ret.hd_buy_potential,
    hd_ref.hd_vehicle_count,
    hd_ref.hd_buy_potential
HAVING COUNT(*) >= 5
ORDER BY total_net_loss DESC
LIMIT 10
