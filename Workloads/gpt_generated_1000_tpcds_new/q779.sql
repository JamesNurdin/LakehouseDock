WITH sampled_customers AS (
    SELECT c_customer_sk,
           c_customer_id,
           c_current_hdemo_sk
    FROM tpcds.customer
    TABLESAMPLE BERNOULLI (10)
),
 demog_income AS (
    SELECT sc.c_customer_sk,
           sc.c_customer_id,
           ib.ib_income_band_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound,
           hd.hd_dep_count,
           hd.hd_vehicle_count
    FROM sampled_customers sc
    JOIN tpcds.household_demographics hd
      ON sc.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 60000
),
 agg_by_income AS (
    SELECT ib_income_band_sk,
           COUNT(DISTINCT c_customer_sk) AS cust_cnt,
           AVG(hd_dep_count) AS avg_dep,
           SUM(hd_vehicle_count) AS total_vehicle
    FROM demog_income
    GROUP BY GROUPING SETS (
        (ib_income_band_sk),
        ()
    )
),
 high_vehicle AS (
    SELECT c_customer_sk
    FROM demog_income
    WHERE hd_vehicle_count >= 5
),
 low_dep AS (
    SELECT c_customer_sk
    FROM demog_income
    WHERE hd_dep_count <= 2
),
 intersect_keys AS (
    SELECT c_customer_sk
    FROM high_vehicle
    INTERSECT
    SELECT c_customer_sk
    FROM low_dep
),
 union_keys AS (
    SELECT c_customer_sk
    FROM demog_income
    WHERE ib_upper_bound <= 120000
    UNION
    SELECT c_customer_sk
    FROM demog_income
    WHERE ib_lower_bound >= 100000
),
 final_keys AS (
    SELECT c_customer_sk
    FROM union_keys
    EXCEPT
    SELECT c_customer_sk
    FROM intersect_keys
)
SELECT f.c_customer_sk,
       a.ib_income_band_sk,
       a.cust_cnt,
       a.avg_dep,
       a.total_vehicle
FROM final_keys f
LEFT JOIN demog_income di
  ON f.c_customer_sk = di.c_customer_sk
LEFT JOIN agg_by_income a
  ON di.ib_income_band_sk = a.ib_income_band_sk
ORDER BY f.c_customer_sk
LIMIT 100
