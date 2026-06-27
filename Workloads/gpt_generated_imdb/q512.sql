WITH keyword_counts AS (
        SELECT mk.movie_id,
               COUNT(DISTINCT mk.keyword_id) AS keyword_cnt
        FROM movie_keyword mk
        GROUP BY mk.movie_id
    ),
    cast_counts AS (
        SELECT ci.movie_id,
               COUNT(DISTINCT ci.person_id) AS cast_cnt
        FROM cast_info ci
        GROUP BY ci.movie_id
    )
SELECT
    t.production_year,
    kt.kind,
    COUNT(DISTINCT t.id) AS total_movies,
    AVG(COALESCE(kc.keyword_cnt, 0)) AS avg_keywords_per_movie,
    AVG(COALESCE(cc.cast_cnt, 0)) AS avg_cast_per_movie
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN keyword_counts kc ON t.id = kc.movie_id
LEFT JOIN cast_counts cc ON t.id = cc.movie_id
WHERE t.production_year >= 2000
GROUP BY t.production_year, kt.kind
ORDER BY t.production_year DESC, total_movies DESC
LIMIT 20
