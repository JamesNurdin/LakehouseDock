WITH store_sales_hourly AS (
    SELECT
        td.t_hour,
        SUM(ss.ss_net_paid) AS store_sales_net_paid,
        SUM(ss.ss_net_profit) AS store_sales_net_profit,
        SUM(ss.ss_quantity) AS store_sales_quantity
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    GROUP BY td.t_hour
),
catalog_sales_hourly AS (
    SELECT
        td.t_hour,
        SUM(cs.cs_net_paid) AS catalog_sales_net_paid,
        SUM(cs.cs_net_profit) AS catalog_sales_net_profit,
        SUM(cs.cs_quantity) AS catalog_sales_quantity
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    GROUP BY td.t_hour
),
web_sales_hourly AS (
    SELECT
        td.t_hour,
        SUM(ws.ws_net_paid) AS web_sales_net_paid,
        SUM(ws.ws_net_profit) AS web_sales_net_profit,
        SUM(ws.ws_quantity) AS web_sales_quantity
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    GROUP BY td.t_hour
),
store_returns_hourly AS (
    SELECT
        td.t_hour,
        SUM(sr.sr_net_loss) AS store_returns_net_loss,
        SUM(sr.sr_return_quantity) AS store_returns_quantity
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    GROUP BY td.t_hour
),
catalog_returns_hourly AS (
    SELECT
        td.t_hour,
        SUM(cr.cr_net_loss) AS catalog_returns_net_loss,
        SUM(cr.cr_return_quantity) AS catalog_returns_quantity
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    GROUP BY td.t_hour
),
web_returns_hourly AS (
    SELECT
        td.t_hour,
        SUM(wr.wr_net_loss) AS web_returns_net_loss,
        SUM(wr.wr_return_quantity) AS web_returns_quantity
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    GROUP BY td.t_hour
)
SELECT
    COALESCE(ss.t_hour, cs.t_hour, ws.t_hour, sr.t_hour, cr.t_hour, wr.t_hour) AS hour_of_day,
    COALESCE(ss.store_sales_net_paid, 0) + COALESCE(cs.catalog_sales_net_paid, 0) + COALESCE(ws.web_sales_net_paid, 0) AS total_sales_net_paid,
    COALESCE(ss.store_sales_net_profit, 0) + COALESCE(cs.catalog_sales_net_profit, 0) + COALESCE(ws.web_sales_net_profit, 0) AS total_sales_net_profit,
    COALESCE(sr.store_returns_net_loss, 0) + COALESCE(cr.catalog_returns_net_loss, 0) + COALESCE(wr.web_returns_net_loss, 0) AS total_returns_net_loss,
    (COALESCE(ss.store_sales_net_paid, 0) + COALESCE(cs.catalog_sales_net_paid, 0) + COALESCE(ws.web_sales_net_paid, 0)
        - COALESCE(sr.store_returns_net_loss, 0) - COALESCE(cr.catalog_returns_net_loss, 0) - COALESCE(wr.web_returns_net_loss, 0)) AS net_revenue,
    COALESCE(ss.store_sales_quantity, 0) + COALESCE(cs.catalog_sales_quantity, 0) + COALESCE(ws.web_sales_quantity, 0) AS total_sales_quantity,
    COALESCE(sr.store_returns_quantity, 0) + COALESCE(cr.catalog_returns_quantity, 0) + COALESCE(wr.web_returns_quantity, 0) AS total_returns_quantity,
    CASE WHEN (COALESCE(ss.store_sales_quantity, 0) + COALESCE(cs.catalog_sales_quantity, 0) + COALESCE(ws.web_sales_quantity, 0)) = 0 THEN NULL
         ELSE (COALESCE(sr.store_returns_quantity, 0) + COALESCE(cr.catalog_returns_quantity, 0) + COALESCE(wr.web_returns_quantity, 0))
              / CAST((COALESCE(ss.store_sales_quantity, 0) + COALESCE(cs.catalog_sales_quantity, 0) + COALESCE(ws.web_sales_quantity, 0)) AS double)
    END AS return_rate
FROM store_sales_hourly ss
FULL OUTER JOIN catalog_sales_hourly cs ON ss.t_hour = cs.t_hour
FULL OUTER JOIN web_sales_hourly ws ON COALESCE(ss.t_hour, cs.t_hour) = ws.t_hour
FULL OUTER JOIN store_returns_hourly sr ON COALESCE(ss.t_hour, cs.t_hour, ws.t_hour) = sr.t_hour
FULL OUTER JOIN catalog_returns_hourly cr ON COALESCE(ss.t_hour, cs.t_hour, ws.t_hour, sr.t_hour) = cr.t_hour
FULL OUTER JOIN web_returns_hourly wr ON COALESCE(ss.t_hour, cs.t_hour, ws.t_hour, sr.t_hour, cr.t_hour) = wr.t_hour
ORDER BY hour_of_day
