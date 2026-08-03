SELECT
    hd.hd_income_band_sk,
    hd.hd_buy_potential,
    COUNT(*) AS sales_cnt,
    SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax
FROM store_sales ss
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE ss.ss_sold_time_sk IN (35137, 60226)
  AND hd.hd_vehicle_count >= 0
GROUP BY hd.hd_income_band_sk, hd.hd_buy_potential
ORDER BY total_net_paid_inc_tax DESC
LIMIT 10
