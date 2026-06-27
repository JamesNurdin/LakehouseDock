WITH
    store_sales_agg AS (
        SELECT
            t.t_hour AS hour_of_day,
            SUM(ss.ss_net_profit) AS store_profit
        FROM store_sales ss
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        WHERE t.t_hour BETWEEN 8 AND 20
        GROUP BY t.t_hour
    ),
    catalog_sales_agg AS (
        SELECT
            t.t_hour AS hour_of_day,
            SUM(cs.cs_net_profit) AS catalog_profit
        FROM catalog_sales cs
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        WHERE t.t_hour BETWEEN 8 AND 20
        GROUP BY t.t_hour
    ),
    web_sales_agg AS (
        SELECT
            t.t_hour AS hour_of_day,
            SUM(ws.ws_net_profit) AS web_profit
        FROM web_sales ws
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        WHERE t.t_hour BETWEEN 8 AND 20
        GROUP BY t.t_hour
    ),
    store_returns_agg AS (
        SELECT
            t.t_hour AS hour_of_day,
            SUM(sr.sr_net_loss) AS store_loss
        FROM store_returns sr
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        WHERE t.t_hour BETWEEN 8 AND 20
        GROUP BY t.t_hour
    ),
    catalog_returns_agg AS (
        SELECT
            t.t_hour AS hour_of_day,
            SUM(cr.cr_net_loss) AS catalog_loss
        FROM catalog_returns cr
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        WHERE t.t_hour BETWEEN 8 AND 20
        GROUP BY t.t_hour
    ),
    web_returns_agg AS (
        SELECT
            t.t_hour AS hour_of_day,
            SUM(wr.wr_net_loss) AS web_loss
        FROM web_returns wr
        JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
        WHERE t.t_hour BETWEEN 8 AND 20
        GROUP BY t.t_hour
    ),
    sales_total AS (
        SELECT
            COALESCE(ss.hour_of_day, cs.hour_of_day, ws.hour_of_day) AS hour_of_day,
            COALESCE(ss.store_profit, 0) + COALESCE(cs.catalog_profit, 0) + COALESCE(ws.web_profit, 0) AS total_sales_profit
        FROM store_sales_agg ss
        FULL OUTER JOIN catalog_sales_agg cs ON ss.hour_of_day = cs.hour_of_day
        FULL OUTER JOIN web_sales_agg ws ON COALESCE(ss.hour_of_day, cs.hour_of_day) = ws.hour_of_day
    ),
    returns_total AS (
        SELECT
            COALESCE(sr.hour_of_day, cr.hour_of_day, wr.hour_of_day) AS hour_of_day,
            COALESCE(sr.store_loss, 0) + COALESCE(cr.catalog_loss, 0) + COALESCE(wr.web_loss, 0) AS total_returns_loss
        FROM store_returns_agg sr
        FULL OUTER JOIN catalog_returns_agg cr ON sr.hour_of_day = cr.hour_of_day
        FULL OUTER JOIN web_returns_agg wr ON COALESCE(sr.hour_of_day, cr.hour_of_day) = wr.hour_of_day
    )
SELECT
    COALESCE(s.hour_of_day, r.hour_of_day) AS hour_of_day,
    COALESCE(s.total_sales_profit, 0) AS total_sales_profit,
    COALESCE(r.total_returns_loss, 0) AS total_returns_loss,
    COALESCE(s.total_sales_profit, 0) - COALESCE(r.total_returns_loss, 0) AS net_margin
FROM sales_total s
FULL OUTER JOIN returns_total r ON s.hour_of_day = r.hour_of_day
ORDER BY hour_of_day
