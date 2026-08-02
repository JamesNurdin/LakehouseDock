WITH bill_stats AS (
    SELECT
        'Bill' AS sales_channel,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_ship_mode_sk IN (1, 8)
      AND hd.hd_vehicle_count >= 1
),
ship_stats AS (
    SELECT
        'Ship' AS sales_channel,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    WHERE ws.ws_ship_mode_sk IN (11, 17)
      AND hd.hd_dep_count <= 4
)
SELECT sales_channel, total_sales, distinct_items
FROM bill_stats
UNION ALL
SELECT sales_channel, total_sales, distinct_items
FROM ship_stats
ORDER BY total_sales DESC
LIMIT 100
