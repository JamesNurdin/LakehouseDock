WITH catalog_qty AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    GROUP BY cs.cs_sold_date_sk
),
web_qty AS (
    SELECT
        ws.ws_sold_date_sk AS sold_date,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY ws.ws_sold_date_sk
),
combined AS (
    SELECT sold_date, total_quantity, 'catalog' AS channel FROM catalog_qty
    UNION ALL
    SELECT sold_date, total_quantity, 'web' AS channel FROM web_qty
)
SELECT
    sold_date,
    channel,
    total_quantity,
    moving_avg_3d,
    CASE
        WHEN moving_avg_3d >= 1000 THEN 'High'
        WHEN moving_avg_3d >= 500 THEN 'Medium'
        ELSE 'Low'
    END AS moving_avg_category,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_quantity DESC) AS quantity_rank
FROM (
    SELECT
        sold_date,
        channel,
        total_quantity,
        AVG(total_quantity) OVER (PARTITION BY channel ORDER BY sold_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg_3d
    FROM combined
) t
ORDER BY sold_date, channel
