WITH filtered_returns AS (
    SELECT
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_cdemo_sk,
        sr.sr_return_quantity,
        sr.sr_return_tax,
        sr.sr_store_credit,
        sr.sr_return_amt_inc_tax
    FROM store_returns sr
    WHERE sr.sr_return_tax > 5.0
)
SELECT
    cd.cd_credit_rating,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    CONCAT(cd.cd_gender, '_', cd.cd_marital_status) AS gender_marital,
    REGEXP_EXTRACT(cd.cd_credit_rating, '(A[0-9])') AS credit_group,
    SUM(fr.sr_return_amt) AS total_return_amt,
    AVG(fr.sr_net_loss) AS avg_net_loss,
    COUNT(*) AS return_cnt,
    CASE
        WHEN SUM(fr.sr_return_amt) > 10000 THEN 'Big'
        ELSE 'Small'
    END AS size_category,
    ROW_NUMBER() OVER (
        PARTITION BY cd.cd_credit_rating
        ORDER BY SUM(fr.sr_return_amt) DESC
    ) AS rank_within_rating
FROM filtered_returns fr
JOIN customer_demographics cd
    ON fr.sr_cdemo_sk = cd.cd_demo_sk
WHERE
    REGEXP_LIKE(cd.cd_credit_rating, '^A[0-9]')
    AND cd.cd_education_status LIKE '%College%'
GROUP BY
    cd.cd_credit_rating,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    CONCAT(cd.cd_gender, '_', cd.cd_marital_status),
    REGEXP_EXTRACT(cd.cd_credit_rating, '(A[0-9])')
ORDER BY total_return_amt DESC
LIMIT 100
