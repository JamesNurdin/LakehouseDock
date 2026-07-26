WITH yearly_sales AS (
    SELECT
        d.d_year,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(cs.cs_net_profit) AS avg_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cs.cs_quantity > 1
    GROUP BY d.d_year
),
site_info AS (
    SELECT
        d.d_year,
        MAX(ws.web_name) FILTER (WHERE ws.web_gmt_offset > 0) AS primary_site_name,
        COUNT(*) AS site_count
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
page_info AS (
    SELECT
        d.d_year,
        COUNT(*) AS page_cnt,
        MIN(wp.wp_type) AS first_page_type
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE wp.wp_char_count > 1000
    GROUP BY d.d_year
)
SELECT
    ys.d_year,
    ys.total_net_paid,
    ys.avg_profit,
    ys.distinct_orders,
    LAG(ys.total_net_paid) OVER (PARTITION BY NULL ORDER BY ys.d_year) AS prev_year_net_paid,
    ROUND(((ys.total_net_paid - LAG(ys.total_net_paid) OVER (ORDER BY ys.d_year)) / NULLIF(LAG(ys.total_net_paid) OVER (ORDER BY ys.d_year), 0)) * 100, 2) AS yoy_growth_percent,
    ROW_NUMBER() OVER (ORDER BY ys.total_net_paid DESC) AS net_paid_rank,
    COALESCE(si.primary_site_name, 'UNKNOWN') AS web_site_name,
    COALESCE(pi.first_page_type, 'UNKNOWN') AS web_page_type,
    CASE
        WHEN ys.total_net_paid >= 10000000 THEN 'Outstanding'
        WHEN ys.total_net_paid >= 5000000 THEN 'Excellent'
        ELSE 'Good'
    END AS performance_tier
FROM yearly_sales ys
LEFT JOIN site_info si ON ys.d_year = si.d_year
LEFT JOIN page_info pi ON ys.d_year = pi.d_year
ORDER BY ys.d_year DESC
