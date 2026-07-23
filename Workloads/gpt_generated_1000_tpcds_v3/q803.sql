WITH returns_by_year AS (
    SELECT 'Store Return' AS activity_type,
           d.d_year AS year,
           SUM(sr.sr_net_loss) AS total_metric
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_holiday = 'Y'
    GROUP BY d.d_year
),
sites_by_year AS (
    SELECT 'Website Opening' AS activity_type,
           d.d_year AS year,
           CAST(SUM(ws.web_tax_percentage) AS decimal(15,2)) AS total_metric
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_holiday = 'N'
    GROUP BY d.d_year
),
combined AS (
    SELECT * FROM returns_by_year
    UNION ALL
    SELECT * FROM sites_by_year
)
SELECT activity_type,
       year,
       total_metric
FROM combined
ORDER BY year ASC, activity_type ASC
LIMIT 100
