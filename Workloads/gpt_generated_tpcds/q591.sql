WITH aggregated AS (
    SELECT
        cd.cd_gender,
        cd.cd_education_status,
        SUM(sr.sr_return_quantity) AS total_quantity,
        SUM(sr.sr_return_amt) AS total_return_amount,
        AVG(sr.sr_net_loss) AS avg_net_loss
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Excellent'
    GROUP BY cd.cd_gender, cd.cd_education_status
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_return_amount DESC) AS rank_within_gender
    FROM aggregated
)
SELECT
    cd_gender,
    cd_education_status,
    total_quantity,
    total_return_amount,
    avg_net_loss,
    rank_within_gender
FROM ranked
WHERE rank_within_gender <= 3
ORDER BY cd_gender, rank_within_gender
