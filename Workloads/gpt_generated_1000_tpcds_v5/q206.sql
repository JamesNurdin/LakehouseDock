WITH filtered AS (
    SELECT
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_return_tax,
        t.t_shift,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        CAST(regexp_extract(cd.cd_credit_rating, '\\d+', 0) AS integer) AS credit_num,
        CASE
            WHEN sr.sr_return_amt > 1000 THEN 'high'
            ELSE 'normal'
        END AS return_category,
        concat(cd.cd_gender, '-', cd.cd_marital_status) AS gender_marital,
        substring(cd.cd_education_status, 1, 3) AS edu_prefix
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(cd.cd_credit_rating, '^A[0-9]+$')
      AND cd.cd_marital_status LIKE 'M%'
      AND t.t_shift = 'second'
)
SELECT
    t_shift,
    edu_prefix,
    return_category,
    COUNT(*) AS returns_cnt,
    SUM(sr_return_amt) AS total_return_amt,
    AVG(sr_return_amt) AS avg_return_amt,
    MAX(credit_num) AS max_credit_num,
    MIN(credit_num) AS min_credit_num
FROM filtered
GROUP BY t_shift, edu_prefix, return_category
ORDER BY avg_return_amt DESC
LIMIT 100
