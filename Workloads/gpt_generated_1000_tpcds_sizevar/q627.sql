SELECT d.cd_gender,
       COUNT(*) AS customer_cnt
FROM tpcds.customer AS c
JOIN tpcds.customer_demographics AS d
  ON c.c_current_cdemo_sk = d.cd_demo_sk
WHERE d.cd_dep_employed_count >= 4
  AND c.c_first_sales_date_sk BETWEEN 2450000 AND 2453000
GROUP BY d.cd_gender
HAVING COUNT(*) > 5
ORDER BY customer_cnt DESC
