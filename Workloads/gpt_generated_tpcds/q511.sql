WITH
    catalog_sales_hour AS (
        SELECT
            td.t_hour AS hour,
            SUM(cs.cs_net_profit) AS catalog_sales_profit
        FROM catalog_sales cs
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        GROUP BY td.t_hour
    ),
    catalog_returns_hour AS (
        SELECT
            td.t_hour AS hour,
            SUM(cr.cr_net_loss) AS catalog_returns_loss
        FROM catalog_returns cr
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        GROUP BY td.t_hour
    ),
    web_sales_hour AS (
        SELECT
            td.t_hour AS hour,
            SUM(ws.ws_net_profit) AS web_sales_profit
        FROM web_sales ws
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        GROUP BY td.t_hour
    ),
    web_returns_hour AS (
        SELECT
            td.t_hour AS hour,
            SUM(wr.wr_net_loss) AS web_returns_loss
        FROM web_returns wr
        JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
        GROUP BY td.t_hour
    ),
    store_returns_hour AS (
        SELECT
            td.t_hour AS hour,
            SUM(sr.sr_net_loss) AS store_returns_loss
        FROM store_returns sr
        JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
        GROUP BY td.t_hour
    ),
    all_hours AS (
        SELECT DISTINCT t_hour AS hour FROM time_dim
    )
SELECT
    ah.hour,
    COALESCE(cs.catalog_sales_profit, 0) AS catalog_sales_profit,
    COALESCE(cr.catalog_returns_loss, 0) AS catalog_returns_loss,
    COALESCE(ws.web_sales_profit, 0) AS web_sales_profit,
    COALESCE(wr.web_returns_loss, 0) AS web_returns_loss,
    COALESCE(sr.store_returns_loss, 0) AS store_returns_loss,
    COALESCE(cs.catalog_sales_profit, 0) + COALESCE(ws.web_sales_profit, 0)
        - COALESCE(cr.catalog_returns_loss, 0) - COALESCE(wr.web_returns_loss, 0) - COALESCE(sr.store_returns_loss, 0) AS net_contribution
FROM all_hours ah
LEFT JOIN catalog_sales_hour cs ON cs.hour = ah.hour
LEFT JOIN catalog_returns_hour cr ON cr.hour = ah.hour
LEFT JOIN web_sales_hour ws ON ws.hour = ah.hour
LEFT JOIN web_returns_hour wr ON wr.hour = ah.hour
LEFT JOIN store_returns_hour sr ON sr.hour = ah.hour
ORDER BY ah.hour
