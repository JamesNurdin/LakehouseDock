WITH agg_sales AS (
    SELECT d.d_year,
           SUM(cs.cs_net_paid_inc_ship) AS net_paid_inc_ship,
           SUM(cs.cs_ext_tax) AS total_tax,
           COUNT(*) FILTER (WHERE cs.cs_coupon_amt > 0) AS coupon_sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
site_names AS (
    SELECT d.d_year,
           MIN(ws.web_name) AS first_web_name,
           MAX(ws.web_name) AS last_web_name
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
page_stats AS (
    SELECT d.d_year,
           AVG(wp.wp_link_count) AS avg_link_count
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    GROUP BY d.d_year
)
SELECT a.d_year,
       a.net_paid_inc_ship,
       a.total_tax,
       a.coupon_sales_cnt,
       SUM(a.net_paid_inc_ship) OVER (ORDER BY a.d_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3yr_sum,
       LAG(a.total_tax) OVER (PARTITION BY a.d_year ORDER BY a.d_year) AS prev_year_tax,
       COALESCE(sn.first_web_name, 'UNKNOWN') AS first_site,
       COALESCE(sn.last_web_name, 'UNKNOWN') AS last_site,
       ps.avg_link_count,
       CASE WHEN a.net_paid_inc_ship > 6000000 THEN 'High' WHEN a.net_paid_inc_ship > 3000000 THEN 'Medium' ELSE 'Low' END AS revenue_category
FROM agg_sales a
LEFT JOIN site_names sn ON a.d_year = sn.d_year
LEFT JOIN page_stats ps ON a.d_year = ps.d_year
ORDER BY a.d_year DESC
