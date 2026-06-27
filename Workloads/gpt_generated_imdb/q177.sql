WITH actor_counts AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movie_base AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kt.kind AS kind
    FROM title t
    JOIN kind_type kt
        ON t.kind_id = kt.id
)
SELECT
    mb.production_year,
    mb.kind,
    COUNT(*) AS movie_count,
    AVG(COALESCE(ac.actor_count, 0)) AS avg_actors_per_movie,
    AVG(COALESCE(kc.keyword_count, 0)) AS avg_keywords_per_movie
FROM movie_base mb
LEFT JOIN actor_counts ac
    ON ac.movie_id = mb.movie_id
LEFT JOIN keyword_counts kc
    ON kc.movie_id = mb.movie_id
WHERE mb.production_year IS NOT NULL
  AND mb.kind = 'movie'
GROUP BY mb.production_year, mb.kind
ORDER BY mb.production_year DESC, movie_count DESC
LIMIT 20
