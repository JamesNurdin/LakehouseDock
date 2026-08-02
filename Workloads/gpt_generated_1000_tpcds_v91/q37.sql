WITH site_open_stats AS (
    SELECT
        d_open.d_quarter_name AS open_quarter,
        w.web_class,
        w.web_state,
        COUNT(*) AS site_count,
        SUM(CASE WHEN w.web_tax_percentage > 0 THEN 1 ELSE 0 END) AS taxable_site_count,
        AVG(w.web_gmt_offset) AS avg_gmt_offset,
        MAX(w.web_gmt_offset) AS max_gmt_offset,
        MIN(w.web_gmt_offset) AS min_gmt_offset
    FROM web_site w
    JOIN date_dim d_open
        ON w.web_open_date_sk = d_open.d_date_sk
    WHERE
        d_open.d_year BETWEEN 2000 AND 2005
        AND w.web_gmt_offset IN (-8.00, -5.00, -7.00)
        AND w.web_state = 'CA'
        AND w.web_tax_percentage >= 0.05
        AND w.web_name LIKE 'site_%'
        AND w.web_class IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM web_site w2
            WHERE w2.web_manager = w.web_manager
              AND w2.web_site_sk <> w.web_site_sk
        )
    GROUP BY ROLLUP (d_open.d_quarter_name, w.web_class, w.web_state)
)
SELECT
    s.open_quarter,
    s.web_class,
    s.web_state,
    s.site_count,
    s.taxable_site_count,
    s.avg_gmt_offset,
    s.max_gmt_offset,
    s.min_gmt_offset,
    (SELECT SUM(t.site_count) FROM site_open_stats t WHERE t.web_state = s.web_state) AS total_sites_state,
    (SELECT AVG(w2.web_gmt_offset) FROM web_site w2 WHERE w2.web_state = s.web_state) AS overall_avg_gmt_offset_state,
    CASE
        WHEN s.avg_gmt_offset <= -7.00 THEN 'West Coast'
        WHEN s.avg_gmt_offset <= -5.00 THEN 'Central'
        ELSE 'Other'
    END AS gmt_region
FROM site_open_stats s
WHERE s.site_count > 0
ORDER BY s.open_quarter ASC NULLS LAST,
         s.web_class ASC NULLS LAST,
         s.web_state ASC NULLS LAST
LIMIT 100
