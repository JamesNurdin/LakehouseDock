WITH catalog_hourly AS (
    SELECT
        t.t_hour AS hour_of_day,
        cs.cs_ext_sales_price AS sales_amount,
        'Catalog' AS channel
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cs.cs_quantity > 0
),
web_hourly AS (
    SELECT
        t.t_hour AS hour_of_day,
        ws.ws_ext_sales_price AS sales_amount,
        'Web' AS channel
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE ws.ws_quantity > 0
)
SELECT
    hour_of_day,
    channel,
    SUM(sales_amount) AS total_sales
FROM (
    SELECT hour_of_day, sales_amount, channel FROM catalog_hourly
    UNION ALL
    SELECT hour_of_day, sales_amount, channel FROM web_hourly
) combined
GROUP BY hour_of_day, channel
ORDER BY hour_of_day, channel
