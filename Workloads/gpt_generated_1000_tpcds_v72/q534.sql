WITH refunded AS (
    SELECT
        cd.cd_gender AS gender,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        'refunded' AS return_type
    FROM tpcds.catalog_returns cr
    JOIN tpcds.customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_return_amount > 1000
      AND cd.cd_purchase_estimate >= 4000
    GROUP BY cd.cd_gender
),
returning AS (
    SELECT
        cd.cd_gender AS gender,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        'returning' AS return_type
    FROM tpcds.catalog_returns cr
    JOIN tpcds.customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_return_amount BETWEEN 500 AND 2000
      AND cd.cd_dep_college_count >= 2
    GROUP BY cd.cd_gender
)
SELECT gender,
       total_return_amount,
       return_cnt,
       return_type
FROM refunded
UNION ALL
SELECT gender,
       total_return_amount,
       return_cnt,
       return_type
FROM returning
ORDER BY total_return_amount DESC, gender
LIMIT 100
