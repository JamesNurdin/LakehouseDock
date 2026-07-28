WITH open_dates AS (
    SELECT
        ws.web_site_sk,
        ws.web_name,
        ws.web_county,
        ws.web_class,
        ws.web_tax_percentage,
        od.d_quarter_name AS open_quarter,
        od.d_year AS open_year,
        od.d_current_year
    FROM web_site ws
    JOIN date_dim od ON ws.web_open_date_sk = od.d_date_sk
    WHERE od.d_current_year = 'Y'
),
close_dates AS (
    SELECT
        ws.web_site_sk,
        cd.d_quarter_name AS close_quarter,
        cd.d_year AS close_year
    FROM web_site ws
    JOIN date_dim cd ON ws.web_close_date_sk = cd.d_date_sk
    WHERE cd.d_quarter_name = '1901Q3'
)
SELECT
    o.open_quarter,
    o.open_year,
    COUNT(*) AS site_count,
    AVG(o.web_tax_percentage) AS avg_tax_pct,
    MIN(o.web_tax_percentage) AS min_tax_pct,
    MAX(o.web_tax_percentage) AS max_tax_pct
FROM open_dates o
JOIN close_dates c ON o.web_site_sk = c.web_site_sk
WHERE o.web_county = 'Bronx County'
  AND o.web_class = 'Unknown'
  AND o.d_current_year = 'Y'
GROUP BY o.open_quarter, o.open_year
ORDER BY site_count DESC
LIMIT 10
