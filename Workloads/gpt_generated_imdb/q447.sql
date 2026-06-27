WITH actor_year_agg AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        t.production_year AS production_year,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        COUNT(DISTINCT cn.id) AS distinct_characters_count
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY n.id, n.name, t.production_year
),
ranked_actors AS (
    SELECT
        person_id,
        person_name,
        production_year,
        movies_count,
        distinct_characters_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movies_count DESC) AS rank_in_year
    FROM actor_year_agg
)
SELECT
    person_id,
    person_name,
    production_year,
    movies_count,
    distinct_characters_count,
    rank_in_year
FROM ranked_actors
WHERE rank_in_year <= 5
ORDER BY production_year DESC, rank_in_year
