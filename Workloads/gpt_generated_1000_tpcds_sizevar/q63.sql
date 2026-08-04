WITH refunded AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        cr.cr_net_loss AS net_loss,
        array[cr.cr_return_quantity, cr.cr_return_amount] AS metrics
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND regexp_like(cd.cd_credit_rating, '^A[0-9]$')
      AND cd.cd_education_status LIKE '%College%'
),
refunded_expanded AS (
    SELECT
        gender,
        education_status,
        net_loss,
        metric_value
    FROM refunded
    CROSS JOIN UNNEST(metrics) AS u(metric_value)
),
returning AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        cr.cr_net_loss AS net_loss,
        array[cr.cr_return_quantity, cr.cr_return_amount] AS metrics
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND regexp_like(cd.cd_credit_rating, '^B[0-9]$')
      AND cd.cd_education_status LIKE '%Graduate%'
),
returning_expanded AS (
    SELECT
        gender,
        education_status,
        net_loss,
        metric_value
    FROM returning
    CROSS JOIN UNNEST(metrics) AS u(metric_value)
),
unioned AS (
    SELECT gender, education_status, net_loss, metric_value FROM refunded_expanded
    UNION DISTINCT
    SELECT gender, education_status, net_loss, metric_value FROM returning_expanded
)
SELECT
    gender,
    education_status,
    SUM(net_loss) AS total_net_loss,
    AVG(metric_value) AS avg_metric_value,
    COUNT(*) AS rows_cnt
FROM unioned
GROUP BY gender, education_status
ORDER BY total_net_loss DESC
LIMIT 100
