SELECT hd.hd_buy_potential, ib.ib_lower_bound, SUM(ss.ss_ext_sales_price) AS total_sales, AVG(ss.ss_net_profit) AS avg_profit
FROM store_sales ss
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE ss.ss_sold_date_sk = 2452252 AND ib.ib_upper_bound <= 90000
GROUP BY hd.hd_buy_potential, ib.ib_lower_bound
