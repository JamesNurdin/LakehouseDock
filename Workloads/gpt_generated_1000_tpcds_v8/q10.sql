WITH morning AS (
    SELECT s.s_store_id,
           SUM(sr.sr_net_loss) AS morning_net_loss
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    CROSS JOIN LATERAL (
        SELECT td.t_sub_shift
        FROM time_dim td
        WHERE td.t_time_sk = sr.sr_return_time_sk
    ) td
    WHERE td.t_sub_shift = 'morning'
    GROUP BY s.s_store_id
),

evening AS (
    SELECT s.s_store_id,
           SUM(sr.sr_net_loss) AS evening_net_loss
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    CROSS JOIN LATERAL (
        SELECT td.t_sub_shift
        FROM time_dim td
        WHERE td.t_time_sk = sr.sr_return_time_sk
    ) td
    WHERE td.t_sub_shift = 'evening'
    GROUP BY s.s_store_id
),

all_losses AS (
    SELECT morning_net_loss AS net_loss FROM morning
    UNION ALL
    SELECT evening_net_loss FROM evening
)
SELECT combined.s_store_id,
       combined.shift,
       combined.net_loss
FROM (
    SELECT m.s_store_id,
           m.morning_net_loss AS net_loss,
           'morning' AS shift
    FROM morning m
    UNION ALL
    SELECT e.s_store_id,
           e.evening_net_loss,
           'evening'
    FROM evening e
) combined
WHERE combined.net_loss > (SELECT AVG(net_loss) FROM all_losses)
ORDER BY combined.net_loss DESC
LIMIT 100
