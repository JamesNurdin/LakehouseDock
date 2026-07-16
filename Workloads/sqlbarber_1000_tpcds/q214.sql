SELECT c.c_customer_id,
       (SELECT ib2.ib_lower_bound FROM income_band ib2 WHERE ib2.ib_income_band_sk = hd.hd_income_band_sk) AS income_lower_bound,
       hd.hd_buy_potential,
       COUNT(*) AS return_count,
       SUM(wr.wr_return_amt) AS total_return_amt
FROM web_returns wr
INNER JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
INNER JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
INNER JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ib.ib_lower_bound > 170001
  AND ib.ib_upper_bound < 180000
  AND c.c_preferred_cust_flag = 'Y'
GROUP BY c.c_customer_id,
         hd.hd_buy_potential,
         (SELECT ib2.ib_lower_bound FROM income_band ib2 WHERE ib2.ib_income_band_sk = hd.hd_income_band_sk)
HAVING SUM(wr.wr_return_amt) > 1945.56
   AND COUNT(*) > 2816.32
