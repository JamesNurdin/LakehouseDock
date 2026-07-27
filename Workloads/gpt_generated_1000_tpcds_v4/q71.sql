/*
Goal: Compare the total sales amount by hour of the day for the catalog and web channels (PM hours 12‑18), classify each hour as High or Low sales, rank the hours within each channel by sales, and show a running cumulative sales total.
The query uses a UNION ALL to combine catalog and web sales, applies a CASE WHEN, a DISTINCT sub‑query, and window functions.
*/
WITH catalog AS (
    SELECT
        'Catalog' AS channel,
        td.t_hour,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_am_pm = 'PM'
      AND td.t_hour BETWEEN 12 AND 18
    GROUP BY td.t_hour
),
web AS (
    SELECT
        'Web' AS channel,
        td.t_hour,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_am_pm = 'PM'
      AND td.t_hour BETWEEN 12 AND 18
    GROUP BY td.t_hour
),
combined AS (
    SELECT * FROM catalog
    UNION ALL
    SELECT * FROM web
)
SELECT
    channel,
    t_hour,
    total_sales,
    CASE WHEN total_sales > 10000 THEN 'High' ELSE 'Low' END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_sales DESC) AS sales_rank,
    SUM(total_sales) OVER (PARTITION BY channel ORDER BY t_hour
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales
FROM (
    SELECT DISTINCT channel, t_hour, total_sales
    FROM combined
) d
ORDER BY channel, t_hour
