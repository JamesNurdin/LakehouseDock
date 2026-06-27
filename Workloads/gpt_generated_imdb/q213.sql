WITH cast_counts AS (
    SELECT movie_id,
           COUNT(*) AS cast_count
    FROM cast_info
    GROUP BY movie_id
),
company_counts AS (
    SELECT movie_id,
           COUNT(DISTINCT company_id) AS company_count
    FROM movie_companies
    GROUP BY movie_id
),
keyword_counts AS (
    SELECT movie_id,
           COUNT(*) AS keyword_count
    FROM movie_keyword
    GROUP BY movie_id
)
SELECT
    t.production_year,
    kt.kind AS kind,
    COUNT(*) AS movie_count,
    AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_movie,
    AVG(COALESCE(compc.company_count, 0)) AS avg_companies_per_movie,
    AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
LEFT JOIN company_counts compc ON t.id = compc.movie_id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
WHERE t.production_year >= 2000
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year DESC, kt.kind
