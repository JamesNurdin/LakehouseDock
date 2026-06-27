WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
movie_keyword_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    JOIN title t ON mk.movie_id = t.id
    GROUP BY t.id
)
SELECT
    mc.production_year,
    mc.kind,
    COUNT(*) AS num_movies,
    AVG(mc.cast_count) AS avg_cast_per_movie,
    AVG(COALESCE(mk.keyword_count, 0)) AS avg_keywords_per_movie
FROM movie_cast_counts mc
LEFT JOIN movie_keyword_counts mk ON mc.movie_id = mk.movie_id
WHERE mc.production_year IS NOT NULL
GROUP BY mc.production_year, mc.kind
ORDER BY mc.production_year DESC, mc.kind
