WITH open_sites AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        dd.d_year AS open_year,
        CASE WHEN dd.d_fy_week_seq > 10 THEN 'High' ELSE 'Low' END AS fy_week_category,
        ws.web_country
    FROM web_site ws
    JOIN date_dim dd
        ON ws.web_open_date_sk = dd.d_date_sk
    WHERE ws.web_country = 'United States'
      AND dd.d_following_holiday = 'N'
),
close_sites AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        dd.d_year AS close_year,
        CASE WHEN dd.d_fy_week_seq > 10 THEN 'High' ELSE 'Low' END AS fy_week_category,
        ws.web_country
    FROM web_site ws
    JOIN date_dim dd
        ON ws.web_close_date_sk = dd.d_date_sk
    WHERE ws.web_country = 'United States'
      AND dd.d_following_holiday = 'Y'
)
SELECT DISTINCT
    site_id,
    site_name,
    year,
    fy_week_category,
    country
FROM (
    SELECT
        web_site_id AS site_id,
        web_name AS site_name,
        open_year AS year,
        fy_week_category,
        web_country AS country
    FROM open_sites
    UNION ALL
    SELECT
        web_site_id AS site_id,
        web_name AS site_name,
        close_year AS year,
        fy_week_category,
        web_country AS country
    FROM close_sites
) AS combined
ORDER BY site_name ASC, year DESC
LIMIT 100
