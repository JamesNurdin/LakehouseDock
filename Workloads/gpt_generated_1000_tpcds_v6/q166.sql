WITH refunded AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        'refunded' AS return_type
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Low Risk'
      AND cr.cr_store_credit > 10
    GROUP BY cd.cd_gender, cd.cd_education_status
),
returning AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        'returning' AS return_type
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_education_status = 'Advanced Degree'
      AND cr.cr_reversed_charge > 100
    GROUP BY cd.cd_gender, cd.cd_education_status
)
SELECT gender, education_status, total_net_loss, return_cnt, return_type
FROM refunded
UNION ALL
SELECT gender, education_status, total_net_loss, return_cnt, return_type
FROM returning
ORDER BY total_net_loss DESC
LIMIT 100
