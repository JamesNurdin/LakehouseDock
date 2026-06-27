WITH cast_counts AS (
    SELECT movie_id,
           COUNT(DISTINCT person_id) AS cast_count
    FROM cast_info
    GROUP BY movie_id
),
keyword_counts AS (
    SELECT movie_id,
           COUNT(DISTINCT keyword_id) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_id
)
SELECT
    kt.kind,
    t.production_year,
    COUNT(DISTINCT t.id) AS num_titles,
    AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_title,
    AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_title
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY kt.kind, t.production_year
ORDER BY num_titles DESC
LIMIT 20
