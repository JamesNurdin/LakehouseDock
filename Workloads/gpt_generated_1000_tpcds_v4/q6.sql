SELECT
    ss.ss_store_sk,
    hd.hd_income_band_sk,
    COUNT(*) AS sales_cnt,
    SUM(ss.ss_net_paid) AS total_net_paid
FROM store_sales AS ss
JOIN household_demographics AS hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE ss.ss_store_sk = 688
  AND hd.hd_dep_count = 5
GROUP BY ss.ss_store_sk, hd.hd_income_band_sk
ORDER BY total_net_paid DESC
LIMIT 100
