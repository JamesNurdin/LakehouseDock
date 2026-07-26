WITH sales_agg AS (
    SELECT
        d.d_year,
        SUM(cs.cs_net_paid_inc_ship_tax) AS net_paid_inc_ship_tax,
        SUM(cs.cs_ext_tax) AS total_tax,
        COUNT(*) AS total_sales,
        AVG(cs.cs_wholesale_cost) AS avg_wholesale_cost
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE cs.cs_ext_tax > 0
    GROUP BY d.d_year
),
site_names AS (
    SELECT
        d.d_year,
        LISTAGG(ws.web_name, '; ') WITHIN GROUP (ORDER BY ws.web_name) AS concatenated_names
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
page_stats AS (
    SELECT
        d.d_year,
        MIN(wp.wp_image_count) AS min_image_cnt,
        MAX(wp.wp_link_count) AS max_link_cnt
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    GROUP BY d.d_year
)
SELECT
    sa.d_year,
    sa.net_paid_inc_ship_tax,
    sa.total_tax,
    sa.total_sales,
    sa.avg_wholesale_cost,
    ROUND(AVG(sa.net_paid_inc_ship_tax) OVER (PARTITION BY NULL ORDER BY sa.d_year ROWS 2 PRECEDING), 2) AS three_year_avg_net_paid,
    COALESCE(sn.concatenated_names, 'UNKNOWN') AS site_names,
    COALESCE(ps.min_image_cnt, 0) AS min_image_count,
    COALESCE(ps.max_link_cnt, 0) AS max_link_count,
    CASE
        WHEN sa.net_paid_inc_ship_tax >= 9000000 THEN 'Platinum'
        WHEN sa.net_paid_inc_ship_tax >= 6000000 THEN 'Gold'
        ELSE 'Silver'
    END AS revenue_class
FROM sales_agg sa
LEFT JOIN site_names sn ON sa.d_year = sn.d_year
LEFT JOIN page_stats ps ON sa.d_year = ps.d_year
ORDER BY sa.d_year ASC
