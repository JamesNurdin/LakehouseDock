WITH catalog_sales_agg AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        td.t_hour AS hour_of_day,
        SUM(cs.cs_net_paid) AS catalog_sales_amount,
        SUM(cs.cs_net_profit) AS catalog_profit_amount,
        CAST(0 AS decimal(7,2)) AS web_sales_amount,
        CAST(0 AS decimal(7,2)) AS web_profit_amount,
        CAST(0 AS decimal(7,2)) AS return_loss_amount
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 17
    GROUP BY sm.sm_ship_mode_id, td.t_hour
),
web_sales_agg AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        td.t_hour AS hour_of_day,
        CAST(0 AS decimal(7,2)) AS catalog_sales_amount,
        CAST(0 AS decimal(7,2)) AS catalog_profit_amount,
        SUM(ws.ws_net_paid) AS web_sales_amount,
        SUM(ws.ws_net_profit) AS web_profit_amount,
        CAST(0 AS decimal(7,2)) AS return_loss_amount
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 17
    GROUP BY sm.sm_ship_mode_id, td.t_hour
),
returns_agg AS (
    SELECT
        sm.sm_ship_mode_id AS ship_mode_id,
        td.t_hour AS hour_of_day,
        CAST(0 AS decimal(7,2)) AS catalog_sales_amount,
        CAST(0 AS decimal(7,2)) AS catalog_profit_amount,
        CAST(0 AS decimal(7,2)) AS web_sales_amount,
        CAST(0 AS decimal(7,2)) AS web_profit_amount,
        SUM(cr.cr_net_loss) AS return_loss_amount
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 8 AND 17
    GROUP BY sm.sm_ship_mode_id, td.t_hour
)
SELECT
    ship_mode_id,
    hour_of_day,
    SUM(catalog_sales_amount) AS total_catalog_sales,
    SUM(catalog_profit_amount) AS total_catalog_profit,
    SUM(web_sales_amount) AS total_web_sales,
    SUM(web_profit_amount) AS total_web_profit,
    SUM(return_loss_amount) AS total_return_loss
FROM (
    SELECT ship_mode_id, hour_of_day, catalog_sales_amount, catalog_profit_amount, web_sales_amount, web_profit_amount, return_loss_amount
    FROM catalog_sales_agg
    UNION ALL
    SELECT ship_mode_id, hour_of_day, catalog_sales_amount, catalog_profit_amount, web_sales_amount, web_profit_amount, return_loss_amount
    FROM web_sales_agg
    UNION ALL
    SELECT ship_mode_id, hour_of_day, catalog_sales_amount, catalog_profit_amount, web_sales_amount, web_profit_amount, return_loss_amount
    FROM returns_agg
) combined
GROUP BY ship_mode_id, hour_of_day
ORDER BY ship_mode_id, hour_of_day
