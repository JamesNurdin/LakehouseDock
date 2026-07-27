WITH filtered_returns AS (
    SELECT
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cd.cd_gender,
        cd.cd_education_status,
        r.r_reason_desc,
        r.r_reason_id
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)product|job')
      AND cd.cd_education_status LIKE '%Degree%'
)
SELECT
    r_reason_desc,
    cd_gender,
    cd_education_status,
    CONCAT(cd_gender, '-', cd_education_status) AS gender_edu_key,
    COUNT(*) AS return_cnt,
    SUM(cr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(cr_net_loss) > 1000 THEN 'High'
        WHEN SUM(cr_net_loss) BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    REGEXP_EXTRACT(r_reason_desc, '(product|job)', 1) AS matched_keyword
FROM filtered_returns
GROUP BY
    r_reason_desc,
    cd_gender,
    cd_education_status,
    CONCAT(cd_gender, '-', cd_education_status),
    REGEXP_EXTRACT(r_reason_desc, '(product|job)', 1)
ORDER BY total_net_loss DESC
LIMIT 100
