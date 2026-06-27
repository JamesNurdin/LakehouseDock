WITH combined_returns AS (
    SELECT cr_reason_sk AS reason_sk,
           cr_returned_time_sk AS time_sk,
           cr_net_loss AS net_loss
    FROM catalog_returns
    UNION ALL
    SELECT sr_reason_sk AS reason_sk,
           sr_return_time_sk AS time_sk,
           sr_net_loss AS net_loss
    FROM store_returns
    UNION ALL
    SELECT wr_reason_sk AS reason_sk,
           wr_returned_time_sk AS time_sk,
           wr_net_loss AS net_loss
    FROM web_returns
)
SELECT r.r_reason_desc,
       t.t_hour,
       SUM(cr.net_loss) AS total_net_loss,
       COUNT(*) AS return_count
FROM combined_returns cr
JOIN reason r ON cr.reason_sk = r.r_reason_sk
JOIN time_dim t ON cr.time_sk = t.t_time_sk
WHERE t.t_hour BETWEEN 8 AND 20
GROUP BY r.r_reason_desc, t.t_hour
ORDER BY total_net_loss DESC
LIMIT 10
