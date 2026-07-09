SELECT hd.hd_income_band_sk,
       hd.hd_buy_potential,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       SUM(sr.sr_net_loss) AS total_return_loss
FROM store_sales ss
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
WHERE hd.hd_vehicle_count > 2
  AND ss.ss_sold_date_sk = 2452274
  AND hd.hd_income_band_sk = 2
GROUP BY hd.hd_income_band_sk, hd.hd_buy_potential
