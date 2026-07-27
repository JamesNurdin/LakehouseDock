WITH cur_week_dates AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_current_week = 'N'
)
SELECT source, return_date, hour, net_loss
FROM (
    SELECT 'catalog' AS source,
           cd.d_date AS return_date,
           td.t_hour AS hour,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN cur_week_dates cd ON cr.cr_returned_date_sk = cd.d_date_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cr.cr_call_center_sk IN (40, 22)
    UNION ALL
    SELECT 'web' AS source,
           cd.d_date AS return_date,
           td.t_hour AS hour,
           wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN cur_week_dates cd ON wr.wr_returned_date_sk = cd.d_date_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE wr.wr_returning_addr_sk IN (1430611, 1581503)
) AS combined
ORDER BY return_date, hour
