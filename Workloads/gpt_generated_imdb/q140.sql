WITH person_movie_stats AS (
    SELECT
        n.id AS person_id,
        n.name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS num_movies,
        COUNT(DISTINCT ci.person_role_id) AS num_roles,
        MIN(t.production_year) AS first_year,
        MAX(t.production_year) AS last_year
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY n.id, n.name, n.gender
)
SELECT
    gender,
    person_id,
    name,
    num_movies,
    num_roles,
    first_year,
    last_year,
    gender_rank
FROM (
    SELECT
        gender,
        person_id,
        name,
        num_movies,
        num_roles,
        first_year,
        last_year,
        RANK() OVER (PARTITION BY gender ORDER BY num_movies DESC) AS gender_rank
    FROM person_movie_stats
    WHERE num_movies >= 50
) ranked
WHERE gender_rank <= 5
ORDER BY gender, gender_rank
