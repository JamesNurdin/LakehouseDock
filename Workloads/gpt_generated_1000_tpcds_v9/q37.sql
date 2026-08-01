WITH sold_sales AS (
    SELECT
        d.d_day_name AS day_name,
        t.t_meal_time AS meal_time,
        'sold' AS date_type,
        concat(d.d_day_name, ' - ', t.t_meal_time) AS day_meal_concat,
        substring(d.d_day_name, 1, 3) AS day_abbr,
        sum(ws.ws_ext_sales_price) AS total_sales,
        sum(ws.ws_quantity) AS total_quantity,
        count(DISTINCT ws.ws_order_number) AS distinct_orders,
        regexp_extract(d.d_day_name, '^([A-Za-z]+)', 1) AS day_name_extracted,
        (
            SELECT count(*)
            FROM web_sales ws2
            INNER JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
            WHERE d2.d_day_name = d.d_day_name
              AND ws2.ws_ext_sales_price > 500
        ) AS high_value_txns
    FROM web_sales ws
    FULL OUTER JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE regexp_like(d.d_day_name, '^T')
      AND t.t_meal_time LIKE '%break%'
    GROUP BY d.d_day_name, t.t_meal_time
),
ship_sales AS (
    SELECT
        d2.d_day_name AS day_name,
        t2.t_meal_time AS meal_time,
        'ship' AS date_type,
        concat(d2.d_day_name, ' - ', t2.t_meal_time) AS day_meal_concat,
        substring(d2.d_day_name, 1, 3) AS day_abbr,
        sum(ws2.ws_ext_sales_price) AS total_sales,
        sum(ws2.ws_quantity) AS total_quantity,
        count(DISTINCT ws2.ws_order_number) AS distinct_orders,
        regexp_extract(d2.d_day_name, '^([A-Za-z]+)', 1) AS day_name_extracted,
        (
            SELECT count(*)
            FROM web_sales ws3
            INNER JOIN date_dim d3 ON ws3.ws_ship_date_sk = d3.d_date_sk
            WHERE d3.d_day_name = d2.d_day_name
              AND ws3.ws_ext_sales_price > 500
        ) AS high_value_txns
    FROM web_sales ws2
    FULL OUTER JOIN date_dim d2 ON ws2.ws_ship_date_sk = d2.d_date_sk
    LEFT JOIN time_dim t2 ON ws2.ws_sold_time_sk = t2.t_time_sk
    WHERE d2.d_day_name LIKE '%day'
      AND t2.t_meal_time LIKE '%lunch%'
    GROUP BY d2.d_day_name, t2.t_meal_time
)
SELECT * FROM sold_sales
UNION ALL
SELECT * FROM ship_sales
ORDER BY total_sales DESC
LIMIT 100
