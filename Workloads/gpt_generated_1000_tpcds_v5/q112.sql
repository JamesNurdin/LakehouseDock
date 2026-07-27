WITH demo_returns AS (
    SELECT
        cd.cd_gender,
        cd.cd_education_status,
        c.c_customer_id,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_amt) AS avg_return_amt
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
        AND cd.cd_education_status = 'Advanced Degree'
        AND wr.wr_returned_time_sk BETWEEN 20000 AND 80000
        AND wr.wr_return_amt > 100
        AND c.c_birth_year > 1970
    GROUP BY cd.cd_gender, cd.cd_education_status, c.c_customer_id
)
SELECT
    dr.cd_gender,
    dr.cd_education_status,
    COUNT(DISTINCT dr.c_customer_id) AS distinct_customers,
    SUM(dr.total_return_amt) AS sum_return_amt,
    AVG(dr.avg_return_amt) AS avg_of_avg_return_amt
FROM demo_returns dr
GROUP BY dr.cd_gender, dr.cd_education_status
HAVING SUM(dr.total_return_amt) > 1000
ORDER BY sum_return_amt DESC
LIMIT 100
