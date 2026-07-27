WITH inventory_summary AS (
    SELECT
        d.d_year,
        ws.web_name,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM inventory i2
                JOIN date_dim d2 ON i2.inv_date_sk = d2.d_date_sk
                WHERE d2.d_year = d.d_year
                  AND i2.inv_quantity_on_hand > 800
            ) THEN 1 ELSE 0
        END AS high_quantity_flag,
        (
            SELECT MAX(i3.inv_quantity_on_hand)
            FROM inventory i3
            JOIN date_dim d3 ON i3.inv_date_sk = d3.d_date_sk
            WHERE d3.d_year = d.d_year
        ) AS max_quantity
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_current_year = 'Y'
    GROUP BY d.d_year, ws.web_name
)

SELECT
    d_year,
    web_name,
    total_quantity,
    high_quantity_flag,
    max_quantity
FROM (
    SELECT
        d_year,
        web_name,
        total_quantity,
        high_quantity_flag,
        max_quantity
    FROM inventory_summary

    UNION ALL

    SELECT
        d.d_year AS d_year,
        ws.web_name AS web_name,
        CAST(0 AS integer) AS total_quantity,
        CAST(0 AS integer) AS high_quantity_flag,
        CAST(NULL AS integer) AS max_quantity
    FROM web_site ws
    JOIN date_dim d ON ws.web_close_date_sk = d.d_date_sk
    WHERE ws.web_mkt_desc LIKE '%Red%'
      AND d.d_current_year = 'Y'
) AS combined
ORDER BY d_year DESC, total_quantity DESC
LIMIT 100
