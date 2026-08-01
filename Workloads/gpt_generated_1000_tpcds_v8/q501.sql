SELECT c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       hd.hd_dep_count,
       hd.hd_vehicle_count
FROM tpcds.customer AS c
JOIN tpcds.household_demographics AS hd
  ON c.c_current_hdemo_sk = hd.hd_demo_sk
WHERE c.c_last_review_date > 2452400
  AND hd.hd_vehicle_count >= 0
LIMIT 100
