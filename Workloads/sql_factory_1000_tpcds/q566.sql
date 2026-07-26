WITH ws_daily_hourly AS (
    SELECT ws.ws_sold_date_sk AS date_sk,
           t.t_hour AS hour,
           SUM(ws.ws_net_profit) AS profit_per_hour
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    GROUP BY ws.ws_sold_date_sk, t.t_hour
), ws_daily AS (
    SELECT date_sk,
           SUM(profit_per_hour) AS total_sales
    FROM ws_daily_hourly
    GROUP BY date_sk
), ws_peak_hour AS (
    SELECT date_sk,
           hour,
           profit_per_hour,
           RANK() OVER (PARTITION BY date_sk ORDER BY profit_per_hour DESC) AS hour_rank
    FROM ws_daily_hourly
), wr_daily AS (
    SELECT wr.wr_returned_date_sk AS date_sk,
           SUM(wr.wr_net_loss) AS total_returns
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
)
SELECT d.d_date,
       d.d_day_name,
       CASE WHEN d.d_holiday = 'Y' THEN 1 ELSE 0 END AS holiday_flag,
       COALESCE(ws.total_sales,0) AS total_sales,
       COALESCE(wr.total_returns,0) AS total_returns,
       COALESCE(ws.total_sales,0) - COALESCE(wr.total_returns,0) AS net_result,
       SUM(COALESCE(ws.total_sales,0) - COALESCE(wr.total_returns,0)) OVER (ORDER BY d.d_date) AS cumulative_net,
       RANK() OVER (ORDER BY COALESCE(ws.total_sales,0) - COALESCE(wr.total_returns,0) DESC) AS profit_rank,
       ph.hour AS peak_sales_hour,
       ph.profit_per_hour AS peak_hour_profit
FROM date_dim d
LEFT JOIN ws_daily ws ON d.d_date_sk = ws.date_sk
LEFT JOIN wr_daily wr ON d.d_date_sk = wr.date_sk
LEFT JOIN (
    SELECT date_sk, hour, profit_per_hour
    FROM ws_peak_hour
    WHERE hour_rank = 1
) ph ON d.d_date_sk = ph.date_sk
WHERE d.d_year = 2001
ORDER BY d.d_date
