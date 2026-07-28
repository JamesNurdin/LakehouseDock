SELECT
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_return_quantity) AS total_return_qty
FROM web_returns wr
JOIN household_demographics hd
  ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_upper_bound >= 100000
  AND hd.hd_buy_potential = '5001-10000'
GROUP BY hd.hd_buy_potential, ib.ib_lower_bound, ib.ib_upper_bound

UNION ALL

SELECT
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(wr.wr_return_quantity) AS total_return_qty
FROM web_returns wr
JOIN household_demographics hd
  ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_lower_bound <= 50000
  AND hd.hd_buy_potential = '1001-5000'
GROUP BY hd.hd_buy_potential, ib.ib_lower_bound, ib.ib_upper_bound
LIMIT 100
