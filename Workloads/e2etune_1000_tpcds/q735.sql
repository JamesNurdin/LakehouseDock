WITH agg AS (
    SELECT
        t.t_shift,
        w.web_country,
        COUNT(*) AS total_rows,
        AVG(w.web_gmt_offset) AS avg_gmt_offset,
        SUM(CASE WHEN w.web_tax_percentage > 0.07 THEN 1 ELSE 0 END) AS high_tax_site_count
    FROM time_dim t
    JOIN web_site w ON true
    WHERE t.t_am_pm = 'PM'
      AND t.t_hour BETWEEN 12 AND 23
      AND w.web_rec_start_date >= DATE '2020-01-01'
      AND w.web_rec_end_date <= DATE '2025-12-31'
    GROUP BY t.t_shift, w.web_country
    HAVING COUNT(*) > 500
)
SELECT
    t_shift,
    web_country,
    total_rows,
    avg_gmt_offset,
    high_tax_site_count,
    RANK() OVER (ORDER BY avg_gmt_offset DESC) AS gmt_offset_rank
FROM agg
ORDER BY avg_gmt_offset DESC
LIMIT 20
