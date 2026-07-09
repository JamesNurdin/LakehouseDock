WITH agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        td.t_shift AS shift,
        hd.hd_buy_potential AS buy_potential,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count,
        AVG(sr.sr_return_amt) AS avg_return_amt
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_education_status IN ('College', '4 yr Degree')
      AND hd.hd_buy_potential = 'High'
    GROUP BY cd.cd_gender, cd.cd_education_status, td.t_shift, hd.hd_buy_potential
    HAVING SUM(sr.sr_net_loss) > 1000
)
SELECT
    gender,
    education_status,
    shift,
    buy_potential,
    total_net_loss,
    return_count,
    avg_return_amt,
    RANK() OVER (ORDER BY total_net_loss DESC) AS net_loss_rank
FROM agg
ORDER BY net_loss_rank
LIMIT 10
