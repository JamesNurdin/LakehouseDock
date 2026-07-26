WITH yearly_sales AS (
    SELECT d.d_year,
           SUM(cs.cs_net_paid) AS total_net_paid,
           SUM(cs.cs_net_profit) AS total_profit,
           COUNT(*) AS sales_cnt,
           AVG(cs.cs_quantity) AS avg_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cs.cs_quantity > 0
    GROUP BY d.d_year
),
site_info AS (
    SELECT d.d_year,
           MAX(ws.web_name) AS max_web_name,
           MIN(ws.web_name) AS min_web_name
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    WHERE ws.web_open_date_sk IS NOT NULL
    GROUP BY d.d_year
),
page_info AS (
    SELECT d.d_year,
           COUNT(DISTINCT wp.wp_type) AS distinct_page_types
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    GROUP BY d.d_year
)
SELECT ys.d_year,
       ys.total_net_paid,
       ys.total_profit,
       ys.sales_cnt,
       ys.avg_quantity,
       LAG(ys.total_profit) OVER (PARTITION BY NULL ORDER BY ys.d_year) AS prev_year_profit,
       ROUND(100.0 * (ys.total_net_paid - LAG(ys.total_net_paid) OVER (ORDER BY ys.d_year)) / NULLIF(LAG(ys.total_net_paid) OVER (ORDER BY ys.d_year),0), 2) AS yoy_growth_percent,
       ROW_NUMBER() OVER (ORDER BY ys.total_profit DESC) AS profit_rank,
       COALESCE(si.max_web_name, 'UNKNOWN') AS max_web_site_name,
       COALESCE(si.min_web_name, 'UNKNOWN') AS min_web_site_name,
       pi.distinct_page_types,
       CASE WHEN ys.total_net_paid > 7000000 THEN 'Outstanding' WHEN ys.total_net_paid > 3000000 THEN 'Good' ELSE 'Fair' END AS performance_tier
FROM yearly_sales ys
LEFT JOIN site_info si ON ys.d_year = si.d_year
LEFT JOIN page_info pi ON ys.d_year = pi.d_year
ORDER BY ys.d_year DESC
