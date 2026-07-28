SELECT
  hd.hd_demo_sk,
  hd.hd_dep_count,
  SUM(ss.ss_net_paid) AS total_net_paid,
  AVG(ss.ss_ext_discount_amt) AS avg_discount
FROM store_sales ss
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_dep_count BETWEEN 1 AND 5
  AND ss.ss_ext_discount_amt > 50.00
GROUP BY hd.hd_demo_sk, hd.hd_dep_count
ORDER BY total_net_paid DESC
LIMIT 100
