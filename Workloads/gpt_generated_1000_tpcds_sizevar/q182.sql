SELECT
    hd.hd_income_band_sk,
    SUM(ss.ss_net_paid_inc_tax) AS total_net_paid_inc_tax,
    COUNT(*) AS sales_count
FROM tpcds.store_sales ss
JOIN tpcds.household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_income_band_sk IN (13, 20)
  AND ss.ss_ext_list_price > 3000
GROUP BY hd.hd_income_band_sk
ORDER BY total_net_paid_inc_tax DESC
