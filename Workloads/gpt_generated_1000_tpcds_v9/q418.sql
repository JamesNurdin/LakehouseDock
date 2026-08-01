SELECT
    c.c_customer_id,
    c.c_last_name,
    h.hd_buy_potential,
    h.hd_vehicle_count
FROM tpcds.customer AS c
JOIN tpcds.household_demographics AS h
    ON c.c_current_hdemo_sk = h.hd_demo_sk
WHERE c.c_last_review_date = 2452573
  AND h.hd_dep_count = 3
ORDER BY c.c_last_name
LIMIT 100
