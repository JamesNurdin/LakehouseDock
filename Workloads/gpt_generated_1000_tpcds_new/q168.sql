WITH recent_customers AS (
   SELECT DISTINCT c_customer_sk
   FROM tpcds.customer
   WHERE c_last_review_date >= 2452500
),
filtered AS (
   SELECT
       cust.c_customer_id,
       cust.c_birth_year,
       cd.cd_gender,
       hd.hd_buy_potential,
       COUNT(*) AS cnt_customers,
       AVG(cd.cd_purchase_estimate) AS avg_purchase_est,
       MIN(hd.hd_vehicle_count) AS min_vehicle_cnt,
       MAX(hd.hd_vehicle_count) AS max_vehicle_cnt
   FROM tpcds.customer AS cust
   JOIN tpcds.customer_demographics AS cd
     ON cust.c_current_cdemo_sk = cd.cd_demo_sk
   JOIN tpcds.household_demographics AS hd
     ON cust.c_current_hdemo_sk = hd.hd_demo_sk
   WHERE cust.c_birth_month = 5
     AND cust.c_birth_day BETWEEN 1 AND 15
     AND cd.cd_marital_status = 'S'
     AND cd.cd_purchase_estimate > 5000
     AND hd.hd_vehicle_count >= 0
     AND hd.hd_buy_potential = '1001-5000'
     AND cust.c_customer_sk NOT IN (SELECT c_customer_sk FROM recent_customers)
   GROUP BY
       cust.c_customer_id,
       cust.c_birth_year,
       cd.cd_gender,
       hd.hd_buy_potential
)
SELECT
    c_customer_id,
    c_birth_year,
    cd_gender,
    hd_buy_potential,
    cnt_customers,
    avg_purchase_est,
    min_vehicle_cnt,
    max_vehicle_cnt
FROM filtered
ORDER BY avg_purchase_est DESC
LIMIT 100
