WITH actor_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        n.gender,
        COUNT(DISTINCT t.id) AS movie_count,
        COUNT(DISTINCT cn.id) AS character_count,
        AVG(t.production_year) AS avg_production_year,
        approx_percentile(t.production_year, 0.5) AS median_production_year
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    JOIN title t
        ON ci.movie_id = t.id
    JOIN char_name cn
        ON ci.person_role_id = cn.id
    WHERE ci.role_id = 1
      AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY n.id, n.name, n.gender
)
SELECT
    person_id,
    person_name,
    gender,
    movie_count,
    character_count,
    avg_production_year,
    median_production_year,
    CAST(character_count AS double) / NULLIF(movie_count, 0) AS avg_characters_per_movie
FROM actor_stats
ORDER BY movie_count DESC, character_count DESC
LIMIT 100
