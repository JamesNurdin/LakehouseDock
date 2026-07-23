WITH dinner_returns AS (
    SELECT
        sr.sr_return_time_sk,
        sr.sr_reason_sk,
        sr.sr_net_loss,
        sr.sr_refunded_cash,
        sr.sr_return_quantity,
        sr.sr_ticket_number,
        t.t_meal_time,
        t.t_time_id
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_meal_time = 'dinner'
        AND REGEXP_LIKE(t.t_time_id, '^AAAAAAA[AB]')
)
SELECT
    r.r_reason_desc,
    r.r_reason_id,
    COUNT(*) AS return_cnt,
    SUM(dr.sr_net_loss) AS total_net_loss,
    AVG(dr.sr_refunded_cash) AS avg_refunded_cash,
    REGEXP_EXTRACT(r.r_reason_desc, '^([^ ]+)') AS first_word_desc,
    CONCAT('Reason_', r.r_reason_id) AS reason_key,
    SUM(dr.sr_net_loss) / (SELECT AVG(sr_net_loss) FROM store_returns) AS loss_ratio_to_overall_avg
FROM dinner_returns dr
JOIN reason r
    ON dr.sr_reason_sk = r.r_reason_sk
WHERE r.r_reason_desc LIKE '%product%'
    OR REGEXP_LIKE(r.r_reason_desc, 'unauth.*')
GROUP BY
    r.r_reason_desc,
    r.r_reason_id,
    REGEXP_EXTRACT(r.r_reason_desc, '^([^ ]+)'),
    CONCAT('Reason_', r.r_reason_id)
HAVING COUNT(*) > 5
ORDER BY total_net_loss DESC
LIMIT 10
