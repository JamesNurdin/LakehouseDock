WITH filtered_demo AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating,
        concat(cd_gender, ' ', cd_marital_status) AS gender_marital,
        regexp_extract(cd_credit_rating, '([A-Z]+)', 1) AS credit_alpha,
        substr(cd_education_status, 1, 10) AS edu_prefix
    FROM
        customer_demographics
    WHERE
        regexp_like(cd_education_status, '^College|^Secondary')
        AND cd_gender LIKE 'M%'
        AND cd_credit_rating IS NOT NULL
)
SELECT
    fd.edu_prefix,
    fd.gender_marital,
    fd.credit_alpha,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(cs.cs_net_profit) AS avg_net_profit
FROM
    filtered_demo fd
JOIN
    catalog_sales cs
    ON cs.cs_bill_cdemo_sk = fd.cd_demo_sk
WHERE
    cs.cs_net_paid_inc_tax > 500
GROUP BY
    fd.edu_prefix,
    fd.gender_marital,
    fd.credit_alpha
ORDER BY
    total_net_paid_inc_tax DESC
LIMIT 100
