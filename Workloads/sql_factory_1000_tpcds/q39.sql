WITH year_sales AS (
    SELECT
        d.d_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_count
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
year_site AS (
    SELECT
        d.d_year,
        MIN(ws.web_name) AS web_name
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
year_page AS (
    SELECT
        d.d_year,
        MIN(wp.wp_type) AS wp_type
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    GROUP BY d.d_year
)
SELECT
    ys.d_year,
    ys.total_net_paid,
    ys.total_profit,
    ys.sales_count,
    LAG(ys.total_net_paid) OVER (ORDER BY ys.d_year) AS prev_year_net_paid,
    CASE
        WHEN LAG(ys.total_net_paid) OVER (ORDER BY ys.d_year) IS NULL THEN NULL
        ELSE (ys.total_net_paid - LAG(ys.total_net_paid) OVER (ORDER BY ys.d_year)) / NULLIF(LAG(ys.total_net_paid) OVER (ORDER BY ys.d_year), 0) * 100
    END AS yoy_growth_percent,
    DENSE_RANK() OVER (ORDER BY ys.total_net_paid DESC) AS net_paid_rank,
    COALESCE(ysite.web_name, 'UNKNOWN') AS web_site_name,
    COALESCE(ypage.wp_type, 'UNKNOWN') AS web_page_type,
    CASE
        WHEN ys.total_net_paid > 5000000 THEN 'Excellent'
        WHEN ys.total_net_paid > 2000000 THEN 'Good'
        ELSE 'Average'
    END AS performance_tier
FROM year_sales ys
LEFT JOIN year_site ysite ON ys.d_year = ysite.d_year
LEFT JOIN year_page ypage ON ys.d_year = ypage.d_year
ORDER BY ys.d_year
