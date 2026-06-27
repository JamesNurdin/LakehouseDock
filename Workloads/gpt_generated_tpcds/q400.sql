WITH catalog_sales_by_hour AS (
    SELECT
        td.t_hour AS hour,
        td.t_shift AS shift,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_quantity) AS catalog_quantity
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    GROUP BY td.t_hour, td.t_shift
),
web_sales_by_hour AS (
    SELECT
        td.t_hour AS hour,
        td.t_shift AS shift,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    GROUP BY td.t_hour, td.t_shift
),
store_returns_by_hour AS (
    SELECT
        td.t_hour AS hour,
        td.t_shift AS shift,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    GROUP BY td.t_hour, td.t_shift
)
SELECT
    COALESCE(cs.hour, ws.hour, sr.hour) AS hour,
    COALESCE(cs.shift, ws.shift, sr.shift) AS shift,
    cs.catalog_net_profit,
    ws.web_net_profit,
    sr.total_net_loss,
    (COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0) - COALESCE(sr.total_net_loss, 0)) AS net_profit_after_returns,
    (COALESCE(cs.catalog_quantity, 0) + COALESCE(ws.web_quantity, 0) - COALESCE(sr.total_return_quantity, 0)) AS net_units_sold
FROM catalog_sales_by_hour cs
FULL OUTER JOIN web_sales_by_hour ws
    ON cs.hour = ws.hour AND cs.shift = ws.shift
FULL OUTER JOIN store_returns_by_hour sr
    ON COALESCE(cs.hour, ws.hour) = sr.hour
    AND COALESCE(cs.shift, ws.shift) = sr.shift
ORDER BY hour, shift
