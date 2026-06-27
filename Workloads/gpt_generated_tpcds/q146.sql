WITH
    catalog_sales_by_hour AS (
        SELECT td.t_hour AS hour_of_day,
               cs.cs_net_profit AS profit
        FROM catalog_sales cs
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    ),
    store_sales_by_hour AS (
        SELECT td.t_hour AS hour_of_day,
               ss.ss_net_profit AS profit
        FROM store_sales ss
        JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    ),
    web_sales_by_hour AS (
        SELECT td.t_hour AS hour_of_day,
               ws.ws_net_profit AS profit
        FROM web_sales ws
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    ),
    catalog_returns_by_hour AS (
        SELECT td.t_hour AS hour_of_day,
               -cr.cr_net_loss AS profit
        FROM catalog_returns cr
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    ),
    store_returns_by_hour AS (
        SELECT td.t_hour AS hour_of_day,
               -sr.sr_net_loss AS profit
        FROM store_returns sr
        JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    ),
    web_returns_by_hour AS (
        SELECT td.t_hour AS hour_of_day,
               -wr.wr_net_loss AS profit
        FROM web_returns wr
        JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    ),
    all_activity AS (
        SELECT hour_of_day, profit FROM catalog_sales_by_hour
        UNION ALL
        SELECT hour_of_day, profit FROM store_sales_by_hour
        UNION ALL
        SELECT hour_of_day, profit FROM web_sales_by_hour
        UNION ALL
        SELECT hour_of_day, profit FROM catalog_returns_by_hour
        UNION ALL
        SELECT hour_of_day, profit FROM store_returns_by_hour
        UNION ALL
        SELECT hour_of_day, profit FROM web_returns_by_hour
    )
SELECT hour_of_day,
       sum(profit) AS net_profit
FROM all_activity
GROUP BY hour_of_day
ORDER BY net_profit DESC
LIMIT 10
