WITH open_sites AS (
    SELECT ws.web_site_id,
           ws.web_name,
           dd.d_year,
           dd.d_quarter_name,
           ws.web_city,
           ws.web_country
    FROM web_site ws
    JOIN date_dim dd ON ws.web_open_date_sk = dd.d_date_sk
    WHERE dd.d_quarter_seq = 1
      AND ws.web_country = 'United States'
      AND EXISTS (
          SELECT 1
          FROM date_dim dd2
          WHERE dd2.d_date_sk = ws.web_close_date_sk
            AND dd2.d_year = dd.d_year
      )
),
close_sites AS (
    SELECT ws.web_site_id,
           ws.web_name,
           dd.d_year,
           dd.d_quarter_name,
           ws.web_city,
           ws.web_country
    FROM web_site ws
    JOIN date_dim dd ON ws.web_close_date_sk = dd.d_date_sk
    WHERE dd.d_quarter_seq = 2
      AND ws.web_city IN ('Georgetown', 'Lakeview')
      AND EXISTS (
          SELECT 1
          FROM date_dim dd2
          WHERE dd2.d_date_sk = ws.web_open_date_sk
            AND dd2.d_year = dd.d_year
      )
),
combined AS (
    SELECT DISTINCT web_site_id, web_name, d_year, d_quarter_name, web_city, web_country
    FROM open_sites
    UNION ALL
    SELECT DISTINCT web_site_id, web_name, d_year, d_quarter_name, web_city, web_country
    FROM close_sites
)
SELECT
    ROW_NUMBER() OVER (ORDER BY d_year DESC, web_site_id) AS row_num,
    web_site_id,
    web_name,
    d_year,
    d_quarter_name,
    web_city,
    web_country
FROM combined
ORDER BY d_year DESC, row_num
LIMIT 100
