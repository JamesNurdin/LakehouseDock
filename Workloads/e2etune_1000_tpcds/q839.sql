WITH reason_hour_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        t.t_hour AS hour_of_day,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_net_loss) AS avg_net_loss,
        SUM(sr.sr_store_credit) AS total_store_credit
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE sr.sr_store_credit > 50
      AND r.r_reason_desc IN ('Package was damaged', 'Stopped working')
    GROUP BY r.r_reason_desc, t.t_hour
)
SELECT
    reason_desc,
    hour_of_day,
    return_cnt,
    total_return_amt,
    avg_net_loss,
    total_store_credit,
    total_store_credit / NULLIF(total_return_amt, 0) AS credit_to_return_ratio,
    RANK() OVER (PARTITION BY hour_of_day ORDER BY total_return_amt DESC) AS reason_rank_by_hour,
    total_return_amt / NULLIF(SUM(total_return_amt) OVER (PARTITION BY hour_of_day), 0) AS pct_of_hour_total
FROM reason_hour_agg
ORDER BY hour_of_day, reason_rank_by_hour
