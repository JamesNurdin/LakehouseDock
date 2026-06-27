WITH info_per_title AS (
    SELECT
        movie_id,
        COUNT(DISTINCT info_type_id) AS info_type_cnt
    FROM movie_info
    GROUP BY movie_id
),
keyword_per_title AS (
    SELECT
        movie_id,
        COUNT(DISTINCT keyword_id) AS keyword_cnt
    FROM movie_keyword
    GROUP BY movie_id
)
SELECT
    kt.kind AS kind,
    COUNT(t.id) AS title_cnt,
    AVG(t.production_year) AS avg_prod_year,
    approx_percentile(t.production_year, 0.5) AS median_prod_year,
    SUM(COALESCE(ip.info_type_cnt, 0)) AS total_info_type_cnt,
    AVG(COALESCE(ip.info_type_cnt, 0)) AS avg_info_type_per_title,
    SUM(COALESCE(kp.keyword_cnt, 0)) AS total_keyword_cnt,
    AVG(COALESCE(kp.keyword_cnt, 0)) AS avg_keyword_per_title
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN info_per_title ip ON ip.movie_id = t.id
LEFT JOIN keyword_per_title kp ON kp.movie_id = t.id
WHERE t.production_year IS NOT NULL
  AND t.production_year >= 2000
GROUP BY kt.kind
ORDER BY title_cnt DESC
