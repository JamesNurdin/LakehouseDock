WITH
    cast_counts AS (
        SELECT ci.movie_id,
               COUNT(DISTINCT ci.person_id) AS cast_count
        FROM cast_info ci
        GROUP BY ci.movie_id
    ),
    company_counts AS (
        SELECT mc.movie_id,
               COUNT(DISTINCT mc.company_id) AS company_count
        FROM movie_companies mc
        GROUP BY mc.movie_id
    ),
    keyword_counts AS (
        SELECT mk.movie_id,
               COUNT(DISTINCT mk.keyword_id) AS keyword_count
        FROM movie_keyword mk
        GROUP BY mk.movie_id
    )
SELECT
    k.kind AS movie_kind,
    t.production_year,
    COUNT(*) AS total_movies,
    AVG(COALESCE(cc.cast_count, 0)) AS avg_cast_per_movie,
    AVG(COALESCE(compc.company_count, 0)) AS avg_companies_per_movie,
    AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie
FROM title t
JOIN kind_type k
    ON t.kind_id = k.id
LEFT JOIN cast_counts cc
    ON t.id = cc.movie_id
LEFT JOIN company_counts compc
    ON t.id = compc.movie_id
LEFT JOIN keyword_counts kc
    ON t.id = kc.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY k.kind, t.production_year
ORDER BY t.production_year DESC, total_movies DESC
LIMIT 100
