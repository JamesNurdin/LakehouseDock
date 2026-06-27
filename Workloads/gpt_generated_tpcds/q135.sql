WITH
    store_sales_agg AS (
        SELECT td.t_hour AS hour,
               SUM(ss.ss_net_profit) AS store_sales_profit
        FROM store_sales ss
        JOIN time_dim td
          ON ss.ss_sold_time_sk = td.t_time_sk
        GROUP BY td.t_hour
    ),
    store_returns_agg AS (
        SELECT td.t_hour AS hour,
               SUM(sr.sr_net_loss) AS store_returns_loss
        FROM store_returns sr
        JOIN time_dim td
          ON sr.sr_return_time_sk = td.t_time_sk
        GROUP BY td.t_hour
    ),
    web_sales_agg AS (
        SELECT td.t_hour AS hour,
               SUM(ws.ws_net_profit) AS web_sales_profit
        FROM web_sales ws
        JOIN time_dim td
          ON ws.ws_sold_time_sk = td.t_time_sk
        GROUP BY td.t_hour
    ),
    web_returns_agg AS (
        SELECT td.t_hour AS hour,
               SUM(wr.wr_net_loss) AS web_returns_loss
        FROM web_returns wr
        JOIN time_dim td
          ON wr.wr_returned_time_sk = td.t_time_sk
        GROUP BY td.t_hour
    ),
    catalog_sales_agg AS (
        SELECT td.t_hour AS hour,
               SUM(cs.cs_net_profit) AS catalog_sales_profit
        FROM catalog_sales cs
        JOIN time_dim td
          ON cs.cs_sold_time_sk = td.t_time_sk
        GROUP BY td.t_hour
    ),
    hours AS (
        SELECT hour FROM store_sales_agg
        UNION
        SELECT hour FROM store_returns_agg
        UNION
        SELECT hour FROM web_sales_agg
        UNION
        SELECT hour FROM web_returns_agg
        UNION
        SELECT hour FROM catalog_sales_agg
    )
SELECT
    h.hour,
    COALESCE(ss.store_sales_profit, 0)          AS store_sales_profit,
    COALESCE(sr.store_returns_loss, 0)          AS store_returns_loss,
    COALESCE(ss.store_sales_profit, 0) - COALESCE(sr.store_returns_loss, 0) AS store_net_profit,
    COALESCE(ws.web_sales_profit, 0)            AS web_sales_profit,
    COALESCE(wr.web_returns_loss, 0)            AS web_returns_loss,
    COALESCE(ws.web_sales_profit, 0) - COALESCE(wr.web_returns_loss, 0) AS web_net_profit,
    COALESCE(cs.catalog_sales_profit, 0)        AS catalog_sales_profit,
    COALESCE(ss.store_sales_profit, 0) - COALESCE(sr.store_returns_loss, 0)
        + COALESCE(ws.web_sales_profit, 0) - COALESCE(wr.web_returns_loss, 0)
        + COALESCE(cs.catalog_sales_profit, 0)   AS total_net_profit
FROM hours h
LEFT JOIN store_sales_agg   ss ON h.hour = ss.hour
LEFT JOIN store_returns_agg sr ON h.hour = sr.hour
LEFT JOIN web_sales_agg    ws ON h.hour = ws.hour
LEFT JOIN web_returns_agg  wr ON h.hour = wr.hour
LEFT JOIN catalog_sales_agg cs ON h.hour = cs.hour
ORDER BY h.hour
