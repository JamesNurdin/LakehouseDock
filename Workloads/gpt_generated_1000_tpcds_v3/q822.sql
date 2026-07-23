WITH site_year_stats AS (
    SELECT
        ws.web_manager,
        ws.web_country,
        od.d_year AS open_year,
        COUNT(*) AS site_cnt,
        SUM(DATE_DIFF('day', od.d_date, cd.d_date)) AS total_lifespan_days,
        AVG(ws.web_gmt_offset) AS avg_gmt_offset,
        AVG(ws.web_tax_percentage) AS avg_tax_percentage
    FROM web_site ws
    JOIN date_dim od ON ws.web_open_date_sk = od.d_date_sk
    JOIN date_dim cd ON ws.web_close_date_sk = cd.d_date_sk
    WHERE ws.web_manager IN ('John Thomas', 'Adam Stonge', 'Charles Parker')
      AND ws.web_country = 'United States'
      AND od.d_weekend = 'N'
      AND cd.d_weekend = 'N'
      AND od.d_current_week = 'N'
    GROUP BY ws.web_manager, ws.web_country, od.d_year
)
SELECT
    web_manager AS manager,
    web_country AS country,
    AVG(total_lifespan_days) AS avg_total_lifespan_days,
    SUM(site_cnt) AS total_site_count,
    AVG(avg_gmt_offset) AS avg_gmt_offset,
    MAX(open_year) AS latest_open_year
FROM site_year_stats
GROUP BY web_manager, web_country
HAVING SUM(site_cnt) > 0
ORDER BY avg_total_lifespan_days DESC
LIMIT 100
