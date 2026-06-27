WITH actor_year AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        t.production_year,
        COUNT(DISTINCT ci.movie_id) AS movies_in_year,
        COUNT(DISTINCT cn.name) AS distinct_characters
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE t.production_year IS NOT NULL
    GROUP BY n.id, n.name, t.production_year
),
ranked_actors AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movies_in_year DESC, person_name) AS rank_in_year
    FROM actor_year
)
SELECT
    production_year,
    person_name,
    movies_in_year,
    distinct_characters
FROM ranked_actors
WHERE rank_in_year <= 5
ORDER BY production_year DESC, rank_in_year
