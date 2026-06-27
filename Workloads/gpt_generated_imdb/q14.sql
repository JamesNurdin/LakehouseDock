WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN cast_info ci
        ON ci.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year, kt.kind
),
movie_keyword_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM title t
    LEFT JOIN movie_keyword mk
        ON mk.movie_id = t.id
    GROUP BY t.id
)
SELECT
    mc.kind,
    COUNT(*) AS num_movies,
    AVG(mc.cast_count) AS avg_cast_per_movie,
    AVG(mk.keyword_count) AS avg_keywords_per_movie,
    MIN(mc.production_year) AS earliest_year,
    MAX(mc.production_year) AS latest_year
FROM movie_cast_counts mc
JOIN movie_keyword_counts mk
    ON mk.movie_id = mc.movie_id
WHERE mc.production_year >= 2000
GROUP BY mc.kind
ORDER BY num_movies DESC
LIMIT 10
