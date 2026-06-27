-- Total net loss and average return quantity per store, reason, gender and household vehicle count for morning returns
WITH morning_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk,
        sr.sr_return_quantity,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_shift = 'Morning'
)
SELECT
    s.s_store_name,
    r.r_reason_desc,
    cd.cd_gender,
    hd.hd_vehicle_count,
    SUM(mr.sr_net_loss) AS total_net_loss,
    AVG(mr.sr_return_quantity) AS avg_return_quantity,
    COUNT(*) AS num_returns
FROM morning_returns mr
JOIN store s
    ON mr.sr_store_sk = s.s_store_sk
JOIN reason r
    ON mr.sr_reason_sk = r.r_reason_sk
JOIN customer_demographics cd
    ON mr.sr_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON mr.sr_hdemo_sk = hd.hd_demo_sk
GROUP BY s.s_store_name, r.r_reason_desc, cd.cd_gender, hd.hd_vehicle_count
ORDER BY total_net_loss DESC
LIMIT 20
