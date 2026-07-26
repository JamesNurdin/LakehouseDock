WITH reason_hourly AS (
    SELECT
        td.t_hour,
        r.r_reason_desc,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    GROUP BY td.t_hour, r.r_reason_desc
)
SELECT *
FROM (
    SELECT
        t_hour,
        r_reason_desc,
        total_net_loss,
        return_cnt,
        CASE
            WHEN total_net_loss > 10000 THEN 'Very High'
            WHEN total_net_loss > 5000 THEN 'High'
            ELSE 'Moderate'
        END AS loss_category,
        RANK() OVER (PARTITION BY t_hour ORDER BY total_net_loss DESC) AS loss_rank
    FROM reason_hourly
) ranked
WHERE loss_rank <= 5
ORDER BY t_hour, loss_rank
