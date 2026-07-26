WITH catalog_hourly AS (
    SELECT
        t.t_hour AS hour,
        t.t_am_pm,
        SUM(cs.cs_net_profit) AS hourly_profit,
        'Catalog' AS channel
    FROM catalog_sales cs
    JOIN time_dim t
      ON cs.cs_sold_time_sk = t.t_time_sk
    GROUP BY t.t_hour, t.t_am_pm
),
web_hourly AS (
    SELECT
        t.t_hour AS hour,
        t.t_am_pm,
        SUM(ws.ws_net_profit) AS hourly_profit,
        'Web' AS channel
    FROM web_sales ws
    JOIN time_dim t
      ON ws.ws_sold_time_sk = t.t_time_sk
    GROUP BY t.t_hour, t.t_am_pm
),
returns_hourly AS (
    SELECT
        t.t_hour AS hour,
        t.t_am_pm,
        -SUM(wr.wr_net_loss) AS hourly_profit,
        'Returns' AS channel
    FROM web_returns wr
    JOIN time_dim t
      ON wr.wr_returned_time_sk = t.t_time_sk
    GROUP BY t.t_hour, t.t_am_pm
),
combined AS (
    SELECT * FROM catalog_hourly
    UNION ALL
    SELECT * FROM web_hourly
    UNION ALL
    SELECT * FROM returns_hourly
)
SELECT
    channel,
    hour,
    t_am_pm,
    hourly_profit,
    SUM(hourly_profit) OVER (PARTITION BY channel ORDER BY hour ROWS UNBOUNDED PRECEDING) AS cumulative_profit,
    hourly_profit - LAG(hourly_profit) OVER (PARTITION BY channel ORDER BY hour) AS profit_change,
    CASE
        WHEN hourly_profit - LAG(hourly_profit) OVER (PARTITION BY channel ORDER BY hour) < -500 THEN 'Significant Drop'
        WHEN hourly_profit - LAG(hourly_profit) OVER (PARTITION BY channel ORDER BY hour) < 0 THEN 'Drop'
        ELSE 'Stable or Increase'
    END AS profit_trend
FROM combined
ORDER BY channel, hour
