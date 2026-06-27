WITH demo_return_stats AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_tax) AS total_return_tax,
        SUM(sr.sr_fee) AS total_fee,
        SUM(sr.sr_return_amt + sr.sr_return_tax + sr.sr_fee) AS total_return_cost,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_dep_count >= 2
    GROUP BY cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_credit_rating
)
SELECT
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_credit_rating,
    total_return_qty,
    total_return_amt,
    total_return_tax,
    total_fee,
    total_return_cost,
    total_net_loss,
    return_cnt,
    total_return_amt / NULLIF(total_return_qty, 0) AS avg_return_amt_per_qty,
    total_net_loss / NULLIF(return_cnt, 0) AS avg_net_loss_per_return,
    CASE
        WHEN total_net_loss > 5000 THEN 'Very High'
        WHEN total_net_loss > 1000 THEN 'High'
        ELSE 'Moderate'
    END AS net_loss_category,
    ROW_NUMBER() OVER (ORDER BY total_return_cost DESC) AS rank_by_cost
FROM demo_return_stats
WHERE total_return_cost > 0
ORDER BY total_return_cost DESC
LIMIT 10
