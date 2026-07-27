WITH cust_demo AS (
    SELECT
        c.c_customer_sk,
        c.c_last_review_date,
        cd.cd_gender,
        cd.cd_credit_rating
    FROM tpcds.customer c
    JOIN tpcds.customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    'recent' AS cohort,
    cd_gender AS gender,
    cd_credit_rating AS credit_rating,
    COUNT(DISTINCT c_customer_sk) AS customer_cnt
FROM cust_demo
WHERE c_last_review_date >= 2452500
GROUP BY cd_gender, cd_credit_rating

UNION ALL

SELECT
    'older' AS cohort,
    cd_gender AS gender,
    cd_credit_rating AS credit_rating,
    COUNT(DISTINCT c_customer_sk) AS customer_cnt
FROM cust_demo
WHERE c_last_review_date < 2452500
GROUP BY cd_gender, cd_credit_rating
ORDER BY cohort, gender, credit_rating
LIMIT 100
