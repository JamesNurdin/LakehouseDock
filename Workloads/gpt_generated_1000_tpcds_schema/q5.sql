WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
    SELECT
        cr.cr_order_number,
        cr.cr_return_amt_inc_tax,
        cs.cs_net_paid_inc_tax,
        cd.cd_education_status,
        regexp_extract_all(cd.cd_education_status, '\\w+') AS edu_words
    FROM sampled_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(cd.cd_education_status, '^.*Degree$')
      AND cd.cd_education_status LIKE '%Degree%'
),
unnested AS (
    SELECT
        cr_order_number,
        cr_return_amt_inc_tax,
        cs_net_paid_inc_tax,
        cd_education_status,
        word
    FROM joined_data
    CROSS JOIN UNNEST(edu_words) AS t(word)
)
SELECT
    cd_education_status,
    COUNT(DISTINCT cr_order_number) AS orders,
    SUM(cr_return_amt_inc_tax) AS total_return_inc_tax,
    SUM(cs_net_paid_inc_tax) AS total_sales_inc_tax,
    SUM(cr_return_amt_inc_tax) / NULLIF(SUM(cs_net_paid_inc_tax), 0) AS return_to_sales_ratio,
    word
FROM unnested
GROUP BY cd_education_status, word
HAVING SUM(cr_return_amt_inc_tax) > 100
ORDER BY total_return_inc_tax DESC
LIMIT 20
