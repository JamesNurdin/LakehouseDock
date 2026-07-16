WITH grouped AS (
    SELECT cd.cd_education_status,
           t.t_shift,
           COUNT(*) AS cust_cnt,
           AVG(cd.cd_purchase_estimate) AS avg_purchase,
           SUM(cd.cd_dep_college_count) AS total_dep_college
    FROM customer_demographics cd
    JOIN time_dim t
      ON (cd.cd_purchase_estimate % 24) = t.t_hour
    WHERE cd.cd_credit_rating IN ('Good', 'Low Risk')
      AND t.t_shift IN ('Morning', 'Afternoon')
    GROUP BY cd.cd_education_status, t.t_shift
    HAVING COUNT(*) > 5
)
SELECT cd_education_status,
       t_shift,
       cust_cnt,
       avg_purchase,
       total_dep_college,
       RANK() OVER (ORDER BY avg_purchase DESC) AS avg_purchase_rank
FROM grouped
ORDER BY avg_purchase DESC
LIMIT 50
