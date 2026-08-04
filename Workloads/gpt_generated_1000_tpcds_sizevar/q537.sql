WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_net_loss,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_dep_college_count
    FROM store_returns sr
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_marital_status = 'M'
      AND cd.cd_education_status = 'College'
      AND cd.cd_purchase_estimate BETWEEN 2000 AND 8000
      AND cd.cd_dep_college_count >= 2
      AND sr.sr_net_loss > 100
      AND sr.sr_return_quantity >= 1
),
aggregated AS (
    SELECT
        sr_store_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        SUM(sr_net_loss) AS total_net_loss,
        AVG(sr_return_amt) AS avg_return_amount,
        COUNT(*) AS return_cnt,
        MIN(sr_return_amt) AS min_return_amt,
        MAX(sr_return_amt) AS max_return_amt
    FROM filtered_returns
    GROUP BY
        sr_store_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status
    HAVING SUM(sr_net_loss) > 1500
)
SELECT
    sr_store_sk,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_net_loss,
    avg_return_amount,
    return_cnt,
    min_return_amt,
    max_return_amt,
    CASE
        WHEN total_net_loss > 5000 THEN 'HIGH'
        WHEN total_net_loss > 2000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_category
FROM aggregated
ORDER BY total_net_loss DESC
OFFSET 0 FETCH NEXT 10 ROWS ONLY
