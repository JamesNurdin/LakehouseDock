WITH daily_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS daily_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_web_site_sk, ws.ws_sold_date_sk
),
site_daily AS (
    SELECT
        wsite.web_name,
        dd.d_date,
        ds.daily_net_profit,
        SUM(ds.daily_net_profit) OVER (PARTITION BY wsite.web_name ORDER BY dd.d_date) AS cumulative_net_profit,
        AVG(ds.daily_net_profit) OVER (
            PARTITION BY wsite.web_name
            ORDER BY dd.d_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS moving_avg_7d_profit
    FROM daily_sales ds
    JOIN web_site wsite ON ds.ws_web_site_sk = wsite.web_site_sk
    JOIN date_dim dd ON ds.ws_sold_date_sk = dd.d_date_sk
)
SELECT
    sd.web_name,
    sd.d_date,
    sd.daily_net_profit,
    sd.cumulative_net_profit,
    CASE
        WHEN sd.cumulative_net_profit > LAG(sd.cumulative_net_profit) OVER (PARTITION BY sd.web_name ORDER BY sd.d_date) THEN 1
        ELSE 0
    END AS profit_growth_flag,
    sd.moving_avg_7d_profit
FROM site_daily sd
ORDER BY sd.web_name, sd.d_date
