WITH demo_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        'REFUNDED' AS demo_type
    FROM catalog_returns cr
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    UNION ALL
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_return_quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        'RETURNING' AS demo_type
    FROM catalog_returns cr
    JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
)
SELECT
    d.d_year,
    dr.demo_type,
    dr.cd_gender,
    dr.cd_marital_status,
    COUNT(*) AS return_count,
    SUM(dr.cr_return_amount) AS total_return_amount,
    SUM(dr.cr_net_loss) AS total_net_loss,
    AVG(dr.cr_return_quantity) AS avg_return_quantity,
    DENSE_RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(dr.cr_net_loss) DESC) AS net_loss_rank_in_year
FROM demo_returns dr
JOIN date_dim d ON dr.cr_returned_date_sk = d.d_date_sk
GROUP BY d.d_year, dr.demo_type, dr.cd_gender, dr.cd_marital_status
ORDER BY d.d_year, net_loss_rank_in_year
