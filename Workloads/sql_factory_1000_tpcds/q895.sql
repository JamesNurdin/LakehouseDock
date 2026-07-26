WITH dept_hourly AS (
    SELECT
        cp.cp_department,
        td.t_hour,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    GROUP BY cp.cp_department, td.t_hour
)
SELECT
    cp_department,
    t_hour,
    total_return_amount,
    total_net_loss,
    RANK() OVER (PARTITION BY t_hour ORDER BY total_return_amount DESC) AS dept_rank_in_hour
FROM dept_hourly
ORDER BY t_hour, dept_rank_in_hour
