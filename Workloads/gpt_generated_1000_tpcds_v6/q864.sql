WITH sales_union AS (
    SELECT
        ws.ws_web_site_sk,
        td.t_hour,
        td.t_am_pm,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE td.t_am_pm = 'PM'
      AND wsit.web_state = 'CA'
    GROUP BY ws.ws_web_site_sk, td.t_hour, td.t_am_pm

    UNION ALL

    SELECT
        ws.ws_web_site_sk,
        td.t_hour,
        td.t_am_pm,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE td.t_am_pm = 'AM'
      AND wsit.web_state = 'NY'
    GROUP BY ws.ws_web_site_sk, td.t_hour, td.t_am_pm
)
SELECT DISTINCT
    wsit.web_name,
    su.t_hour,
    su.t_am_pm,
    su.total_profit,
    su.distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY su.t_hour ORDER BY su.total_profit DESC) AS profit_rank
FROM sales_union su
JOIN web_site wsit ON su.ws_web_site_sk = wsit.web_site_sk
ORDER BY su.t_hour, profit_rank
LIMIT 100
