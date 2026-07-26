WITH yearly_aggregates AS (
    SELECT
        d.d_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_count,
        MAX(cs.cs_net_paid) AS max_single_sale
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
site_rank AS (
    SELECT
        d.d_year,
        ws.web_name,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY ws.web_gmt_offset DESC) AS rn
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
),
page_stats AS (
    SELECT
        d.d_year,
        wp.wp_type,
        AVG(wp.wp_link_count) AS avg_links
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    GROUP BY d.d_year, wp.wp_type
)
SELECT
    ya.d_year,
    ya.total_net_paid,
    ya.total_profit,
    ya.sales_count,
    ya.max_single_sale,
    LAG(ya.total_net_paid) OVER (ORDER BY ya.d_year) AS prev_year_net_paid,
    (ya.total_net_paid - LAG(ya.total_net_paid) OVER (ORDER BY ya.d_year)) / NULLIF(LAG(ya.total_net_paid) OVER (ORDER BY ya.d_year),0) * 100 AS yoy_change_pct,
    sr.web_name AS top_site_by_gmt_offset,
    ps.wp_type,
    ps.avg_links,
    CASE WHEN ya.total_net_paid > 6000000 THEN 'Tier A'
         WHEN ya.total_net_paid > 3000000 THEN 'Tier B'
         ELSE 'Tier C' END AS tier
FROM yearly_aggregates ya
LEFT JOIN site_rank sr ON ya.d_year = sr.d_year AND sr.rn = 1
LEFT JOIN page_stats ps ON ya.d_year = ps.d_year
ORDER BY ya.d_year
