SELECT hd.hd_income_band_sk,
       hd.hd_buy_potential,
       SUM(cs.cs_net_paid) AS total_sales,
       SUM(sr.sr_net_loss) AS total_return_loss
FROM household_demographics AS hd
JOIN catalog_sales AS cs ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN store_returns AS sr ON sr.sr_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_vehicle_count > 1
GROUP BY hd.hd_income_band_sk, hd.hd_buy_potential
