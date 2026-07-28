WITH store_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(sr.sr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY r.r_reason_desc
),
web_agg AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt,
        CASE WHEN SUM(wr.wr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY r.r_reason_desc
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
)
SELECT
    reason_desc,
    total_loss,
    return_cnt,
    loss_category,
    ROW_NUMBER() OVER (PARTITION BY loss_category ORDER BY total_loss DESC) AS loss_rank,
    (SELECT AVG(total_loss) FROM combined) AS avg_total_loss_all
FROM combined
ORDER BY total_loss DESC
LIMIT 100
