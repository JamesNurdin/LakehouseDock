/*
Goal: Compare the volume of returns from the catalog channel versus the web channel by hour and minute of the day, aggregating total return amount and net loss, and list the results ordered chronologically and by source.
*/
WITH catalog_ret AS (
    SELECT
        td.t_hour AS hour,
        td.t_minute AS minute,
        td.t_sub_shift AS sub_shift,
        'catalog' AS source,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE cr.cr_return_amount > 10
      AND td.t_hour BETWEEN 8 AND 20
    GROUP BY td.t_hour, td.t_minute, td.t_sub_shift
),
web_ret AS (
    SELECT
        td.t_hour AS hour,
        td.t_minute AS minute,
        td.t_sub_shift AS sub_shift,
        'web' AS source,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE wr.wr_return_amt > 10
      AND td.t_hour BETWEEN 8 AND 20
    GROUP BY td.t_hour, td.t_minute, td.t_sub_shift
)
SELECT hour,
       minute,
       sub_shift,
       source,
       total_return_amount,
       total_net_loss
FROM catalog_ret
UNION ALL
SELECT hour,
       minute,
       sub_shift,
       source,
       total_return_amount,
       total_net_loss
FROM web_ret
ORDER BY hour,
         minute,
         source
LIMIT 100
