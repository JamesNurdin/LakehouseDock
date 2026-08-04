SELECT
    hd.hd_buy_potential,
    COUNT(DISTINCT c.c_customer_id) AS customer_cnt
FROM tpcds.customer c
JOIN tpcds.household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_dep_count = 5
GROUP BY hd.hd_buy_potential
ORDER BY customer_cnt DESC
