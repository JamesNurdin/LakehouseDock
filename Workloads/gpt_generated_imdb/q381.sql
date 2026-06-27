WITH joined_cast AS (
    SELECT
        ci.person_id,
        ci.movie_id,
        ci.person_role_id,
        ci.nr_order,
        n.gender,
        t.production_year
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    JOIN title t
        ON ci.movie_id = t.id
    JOIN char_name cn
        ON ci.person_role_id = cn.id
    WHERE n.gender IS NOT NULL
      AND t.kind_id = 1
)
SELECT
    production_year,
    gender,
    COUNT(DISTINCT person_id) AS total_actors,
    COUNT(DISTINCT movie_id) AS total_movies,
    COUNT(DISTINCT person_role_id) AS total_roles,
    AVG(nr_order) AS avg_nr_order,
    CAST(COUNT(DISTINCT person_role_id) AS double) / NULLIF(COUNT(DISTINCT person_id), 0) AS roles_per_actor
FROM joined_cast
GROUP BY production_year, gender
ORDER BY production_year DESC, gender
