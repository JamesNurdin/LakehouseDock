WITH filtered AS (
    SELECT
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_net_loss,
        sr.sr_return_time_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk,
        td.t_hour,
        td.t_shift,
        cd.cd_gender,
        cd.cd_education_status,
        cd.cd_marital_status,
        hd.hd_vehicle_count,
        hd.hd_income_band_sk
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_education_status = 'College'
      AND td.t_hour BETWEEN 9 AND 18
      AND hd.hd_vehicle_count >= 1
),
bucketed AS (
    SELECT
        *,
        CASE
            WHEN t_hour BETWEEN 9 AND 11 THEN 'Morning'
            WHEN t_hour BETWEEN 12 AND 14 THEN 'Midday'
            WHEN t_hour BETWEEN 15 AND 17 THEN 'Afternoon'
            ELSE 'Evening'
        END AS hour_bucket
    FROM filtered
),
aggregated AS (
    SELECT
        hour_bucket,
        cd_marital_status,
        COUNT(*) AS returns_cnt,
        SUM(sr_net_loss) AS total_net_loss,
        AVG(sr_net_loss) AS avg_net_loss,
        SUM(sr_return_amt) AS total_return_amt,
        CASE WHEN SUM(sr_return_amt) = 0 THEN NULL
             ELSE ROUND(SUM(sr_net_loss) / SUM(sr_return_amt), 4)
        END AS loss_to_amount_ratio
    FROM bucketed
    GROUP BY hour_bucket, cd_marital_status
    HAVING COUNT(*) > 20
)
SELECT
    hour_bucket,
    cd_marital_status,
    returns_cnt,
    total_net_loss,
    avg_net_loss,
    total_return_amt,
    loss_to_amount_ratio,
    RANK() OVER (PARTITION BY cd_marital_status ORDER BY avg_net_loss DESC) AS net_loss_rank
FROM aggregated
ORDER BY hour_bucket, net_loss_rank
LIMIT 15
