WITH weekly_stats AS (
    SELECT
        d.d_week_seq,
        cc.cc_call_center_sk,
        cc.cc_name AS call_center_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_week_seq BETWEEN 10 AND 20
      AND t.t_minute IN (1, 12, 15)
      AND cr.cr_return_amount > 500
      AND d.d_date >= DATE '2022-01-01'
    GROUP BY d.d_week_seq, cc.cc_call_center_sk, cc.cc_name
)
SELECT
    ws.d_week_seq,
    ws.call_center_name,
    ws.total_return_amount,
    ws.total_net_loss,
    CASE
        WHEN ws.total_net_loss > 10000 THEN 'High Loss'
        WHEN ws.total_net_loss > 5000 THEN 'Medium Loss'
        ELSE 'Low Loss'
    END AS loss_category,
    (
        SELECT AVG(DISTINCT total_net_loss)
        FROM (
            SELECT SUM(cr2.cr_net_loss) AS total_net_loss
            FROM catalog_returns cr2
            JOIN date_dim d2 ON cr2.cr_returned_date_sk = d2.d_date_sk
            WHERE d2.d_week_seq = ws.d_week_seq
            GROUP BY cr2.cr_call_center_sk
        ) sub
    ) AS avg_net_loss_per_week,
    RANK() OVER (PARTITION BY ws.d_week_seq ORDER BY ws.total_net_loss DESC) AS net_loss_rank
FROM weekly_stats ws
ORDER BY ws.d_week_seq, net_loss_rank
LIMIT 100
