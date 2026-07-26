WITH reason_stats AS (
    SELECT
        r.r_reason_desc,
        td.t_hour,
        SUM(cr.cr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    GROUP BY r.r_reason_desc, td.t_hour
),
sales_stats AS (
    SELECT
        td.t_hour,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    GROUP BY td.t_hour
)
SELECT
    rs.r_reason_desc,
    rs.t_hour,
    rs.total_loss,
    ss.total_sales,
    rs.total_loss / NULLIF(ss.total_sales, 0) AS loss_to_sales_ratio,
    CASE
        WHEN rs.total_loss > 5000 THEN 'High Loss'
        ELSE 'Low/Moderate Loss'
    END AS loss_category,
    RANK() OVER (PARTITION BY rs.t_hour ORDER BY rs.total_loss DESC) AS loss_rank_hour,
    DENSE_RANK() OVER (ORDER BY rs.total_loss / NULLIF(ss.total_sales, 0) DESC) AS overall_loss_ratio_rank
FROM reason_stats rs
JOIN sales_stats ss
    ON rs.t_hour = ss.t_hour
WHERE rs.total_loss > 0
ORDER BY rs.t_hour, loss_rank_hour
