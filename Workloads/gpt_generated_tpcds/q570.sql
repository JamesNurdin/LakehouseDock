WITH catalog_agg AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(cr.cr_order_number) AS catalog_return_count,
        SUM(cr.cr_return_quantity) AS catalog_return_quantity,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        AVG(cr.cr_return_amount) AS catalog_avg_return_amount
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
store_agg AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(sr.sr_ticket_number) AS store_return_count,
        SUM(sr.sr_return_quantity) AS store_return_quantity,
        SUM(sr.sr_return_amt) AS store_return_amount,
        SUM(sr.sr_net_loss) AS store_net_loss,
        AVG(sr.sr_return_amt) AS store_avg_return_amount
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT
    COALESCE(ca.cd_gender, sa.cd_gender) AS gender,
    COALESCE(ca.cd_marital_status, sa.cd_marital_status) AS marital_status,
    COALESCE(ca.cd_education_status, sa.cd_education_status) AS education_status,
    ca.catalog_return_count,
    sa.store_return_count,
    ca.catalog_return_quantity,
    sa.store_return_quantity,
    ca.catalog_return_amount,
    sa.store_return_amount,
    ca.catalog_net_loss,
    sa.store_net_loss,
    ca.catalog_avg_return_amount,
    sa.store_avg_return_amount,
    (ca.catalog_net_loss + sa.store_net_loss) AS total_net_loss,
    CASE
        WHEN (ca.catalog_net_loss + sa.store_net_loss) = 0 THEN 0
        ELSE ca.catalog_net_loss / (ca.catalog_net_loss + sa.store_net_loss)
    END AS catalog_net_loss_share,
    CASE
        WHEN sa.store_avg_return_amount = 0 THEN NULL
        ELSE ca.catalog_avg_return_amount / sa.store_avg_return_amount
    END AS catalog_vs_store_avg_return_ratio,
    RANK() OVER (ORDER BY (ca.catalog_net_loss + sa.store_net_loss) DESC) AS net_loss_rank
FROM catalog_agg ca
FULL OUTER JOIN store_agg sa
    ON ca.cd_demo_sk = sa.cd_demo_sk
WHERE (ca.catalog_return_count IS NOT NULL OR sa.store_return_count IS NOT NULL)
ORDER BY total_net_loss DESC
LIMIT 100
