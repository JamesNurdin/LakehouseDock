WITH recent_sales AS (
    SELECT
        ws.ws_order_number,
        sm.sm_carrier,
        t.t_hour,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
    FROM web_sales ws
    INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    INNER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 120 AND 123
      AND NOT EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_order_number = ws.ws_order_number
            AND ws2.ws_net_profit > 5000
      )
    GROUP BY ws.ws_order_number, sm.sm_carrier, t.t_hour
),
earlier_sales AS (
    SELECT
        ws.ws_order_number,
        sm.sm_carrier,
        t.t_hour,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
    FROM web_sales ws
    INNER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    INNER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2000
      AND d.d_month_seq BETWEEN 108 AND 111
      AND NOT EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_order_number = ws.ws_order_number
            AND ws2.ws_net_profit > 5000
      )
    GROUP BY ws.ws_order_number, sm.sm_carrier, t.t_hour
)
SELECT * FROM (
    SELECT ws_order_number, sm_carrier, t_hour, total_sales, profit_flag
    FROM recent_sales
    UNION ALL
    SELECT ws_order_number, sm_carrier, t_hour, total_sales, profit_flag
    FROM earlier_sales
) AS combined
ORDER BY total_sales DESC, profit_flag
LIMIT 100
