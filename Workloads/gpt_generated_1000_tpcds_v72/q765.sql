WITH store_part AS (
    SELECT
        t.t_hour AS hour_of_day,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        'store' AS channel
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_quantity > 5
      AND cd.cd_gender = 'M'
      AND t.t_am_pm = 'PM'
    GROUP BY t.t_hour
),
web_part AS (
    SELECT
        t.t_hour AS hour_of_day,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        'web' AS channel
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE ws.ws_quantity > 5
      AND ws.ws_ext_sales_price > 1000
      AND sm.sm_type = 'EXPRESS'
      AND t.t_am_pm = 'AM'
    GROUP BY t.t_hour
)
SELECT hour_of_day, total_sales, channel
FROM store_part
UNION ALL
SELECT hour_of_day, total_sales, channel
FROM web_part
ORDER BY hour_of_day, total_sales DESC
LIMIT 100
