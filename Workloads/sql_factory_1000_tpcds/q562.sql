WITH sales_by_month AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(cs.cs_net_paid) AS month_net_paid,
        SUM(cs.cs_net_profit) AS month_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_month_seq BETWEEN 1 AND 12
    GROUP BY d.d_year, d.d_month_seq
),
site_info AS (
    SELECT
        d.d_year,
        MIN(ws.web_name) AS web_name,
        AVG(ws.web_gmt_offset) AS avg_gmt_offset
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    GROUP BY d.d_year
),
page_info AS (
    SELECT
        d.d_year,
        MIN(wp.wp_type) AS wp_type,
        SUM(wp.wp_char_count) AS total_char_count
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    GROUP BY d.d_year
)
SELECT
    sbm.d_year,
    sbm.d_month_seq,
    sbm.month_net_paid,
    sbm.month_profit,
    LAG(sbm.month_net_paid) OVER (PARTITION BY sbm.d_year ORDER BY sbm.d_month_seq) AS prev_month_net_paid,
    CASE WHEN LAG(sbm.month_net_paid) OVER (PARTITION BY sbm.d_year ORDER BY sbm.d_month_seq) IS NULL THEN NULL
         ELSE (sbm.month_net_paid - LAG(sbm.month_net_paid) OVER (PARTITION BY sbm.d_year ORDER BY sbm.d_month_seq)) / NULLIF(LAG(sbm.month_net_paid) OVER (PARTITION BY sbm.d_year ORDER BY sbm.d_month_seq),0) * 100 END AS mom_growth_percent,
    COALESCE(si.web_name, 'UNKNOWN') AS web_site_name,
    COALESCE(pi.wp_type, 'UNKNOWN') AS web_page_type,
    si.avg_gmt_offset,
    pi.total_char_count,
    CASE WHEN sbm.month_net_paid > 1000000 THEN 'High'
         WHEN sbm.month_net_paid > 500000 THEN 'Medium'
         ELSE 'Low' END AS month_performance
FROM sales_by_month sbm
LEFT JOIN site_info si ON sbm.d_year = si.d_year
LEFT JOIN page_info pi ON sbm.d_year = pi.d_year
ORDER BY sbm.d_year, sbm.d_month_seq
