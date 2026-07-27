WITH refunded AS (
    SELECT
        cd.cd_demo_sk AS demo_sk,
        SUM(cr.cr_return_amount) AS total_amount,
        COUNT(*) AS transaction_cnt,
        'refunded' AS customer_type
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_purchase_estimate > 5000
      AND cr.cr_fee > 20
    GROUP BY cd.cd_demo_sk
),
returning AS (
    SELECT
        cd.cd_demo_sk AS demo_sk,
        SUM(cr.cr_return_amount) AS total_amount,
        COUNT(*) AS transaction_cnt,
        'returning' AS customer_type
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_purchase_estimate < 3000
      AND cr.cr_fee > 20
    GROUP BY cd.cd_demo_sk
)
SELECT
    demo_sk,
    total_amount,
    transaction_cnt,
    customer_type
FROM refunded
UNION ALL
SELECT
    demo_sk,
    total_amount,
    transaction_cnt,
    customer_type
FROM returning
LIMIT 100
