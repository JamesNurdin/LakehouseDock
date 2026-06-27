WITH actor_movie_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        COUNT(DISTINCT ci.movie_id) AS num_movies,
        COUNT(DISTINCT kt.kind) AS num_kinds,
        MIN(t.production_year) AS earliest_year,
        MAX(t.production_year) AS latest_year
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    GROUP BY n.id, n.name
),
actor_alternate_names AS (
    SELECT
        an.person_id,
        ARRAY_AGG(DISTINCT an.name) AS alt_names
    FROM aka_name an
    GROUP BY an.person_id
)
SELECT
    ams.person_name,
    ams.num_movies,
    ams.num_kinds,
    ams.earliest_year,
    ams.latest_year,
    slice(aan.alt_names, 1, 3) AS sample_alternate_names
FROM actor_movie_stats ams
LEFT JOIN actor_alternate_names aan ON ams.person_id = aan.person_id
ORDER BY ams.num_movies DESC
LIMIT 10
