WITH site_stats AS (
    SELECT
        ws.web_mkt_class,
        COUNT(*) AS site_cnt,
        AVG(ws.web_tax_percentage) AS avg_tax_pct
    FROM web_site ws
    JOIN date_dim od ON ws.web_open_date_sk = od.d_date_sk
    GROUP BY ws.web_mkt_class
)
SELECT
    web_mkt_class,
    site_cnt,
    avg_tax_pct,
    RANK() OVER (ORDER BY avg_tax_pct DESC) AS tax_pct_rank,
    CASE
        WHEN avg_tax_pct > 0.15 THEN 'High'
        ELSE 'Low'
    END AS tax_category,
    DENSE_RANK() OVER (ORDER BY site_cnt DESC) AS site_cnt_rank
FROM site_stats
ORDER BY tax_pct_rank
