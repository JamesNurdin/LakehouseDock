SELECT
    cd.cd_education_status,
    cd.cd_credit_rating,
    COUNT(DISTINCT c.c_customer_id) AS distinct_customer_count
FROM tpcds.customer c
JOIN tpcds.customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_education_status = 'College'
  AND c.c_last_review_date > 2452400
GROUP BY cd.cd_education_status, cd.cd_credit_rating
ORDER BY distinct_customer_count DESC, cd.cd_education_status
