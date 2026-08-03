SELECT
  c.c_customer_id,
  c.c_first_name,
  c.c_last_name,
  hd.hd_buy_potential
FROM
  tpcds.customer AS c
JOIN
  tpcds.household_demographics AS hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE
  hd.hd_dep_count = 3
  AND hd.hd_buy_potential = '501-1000'
