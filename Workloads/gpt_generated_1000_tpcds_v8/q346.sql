SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    hd.hd_buy_potential,
    hd.hd_dep_count
FROM tpcds.customer c
JOIN tpcds.household_demographics hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND hd.hd_buy_potential = '>10000'
ORDER BY c.c_customer_id
LIMIT 100
