WITH movie_cast_counts AS (
    SELECT
        t.id AS movie_id,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN cast_info ci ON ci.movie_id = t.id
    WHERE kt.kind = 'movie'
      AND t.production_year IS NOT NULL
    GROUP BY t.id, t.production_year
),
actors_per_year AS (
    SELECT
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS distinct_actor_count
    FROM title t
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN cast_info ci ON ci.movie_id = t.id
    WHERE kt.kind = 'movie'
      AND t.production_year IS NOT NULL
    GROUP BY t.production_year
)
SELECT
    mc.production_year,
    COUNT(*) AS movie_count,
    SUM(mc.cast_count) AS total_cast,
    AVG(mc.cast_count) AS avg_cast_per_movie,
    apy.distinct_actor_count
FROM movie_cast_counts mc
JOIN actors_per_year apy
    ON apy.production_year = mc.production_year
GROUP BY mc.production_year, apy.distinct_actor_count
ORDER BY mc.production_year
