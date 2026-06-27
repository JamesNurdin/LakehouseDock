WITH movies_per_year AS (
    SELECT t.production_year,
           COUNT(DISTINCT t.id) AS movie_count
    FROM title t
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year
),
actors_per_year AS (
    SELECT t.production_year,
           COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year
),
keywords_per_year AS (
    SELECT t.production_year,
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    JOIN title t ON mk.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.production_year
)
SELECT m.production_year,
       m.movie_count,
       a.actor_count,
       k.keyword_count,
       CAST(k.keyword_count AS double) / NULLIF(m.movie_count, 0) AS avg_keywords_per_movie
FROM movies_per_year m
LEFT JOIN actors_per_year a ON m.production_year = a.production_year
LEFT JOIN keywords_per_year k ON m.production_year = k.production_year
ORDER BY m.production_year DESC
