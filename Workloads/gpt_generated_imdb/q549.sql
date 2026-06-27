/*
  Top 10 actors (by number of movies) from the year 2000‑2020,
  showing overall acting statistics and their most recent movie.
  Joins follow the allowed relationships only.
*/
WITH actor_movies AS (
    SELECT
        name.id            AS actor_id,
        name.name          AS actor_name,
        title.id           AS movie_id,
        title.title        AS movie_title,
        title.production_year AS year,
        char_name.name     AS role_name,
        cast_info.nr_order AS nr_order,
        kind_type.kind     AS kind
    FROM cast_info
    JOIN name       ON cast_info.person_id   = name.id
    JOIN title      ON cast_info.movie_id    = title.id
    JOIN char_name  ON cast_info.person_role_id = char_name.id
    JOIN kind_type  ON title.kind_id = kind_type.id
    WHERE kind_type.kind = 'movie'
      AND title.production_year BETWEEN 2000 AND 2020
),
actor_stats AS (
    SELECT
        actor_id,
        actor_name,
        COUNT(DISTINCT movie_id)                AS total_movies,
        MIN(year)                               AS first_year,
        MAX(year)                               AS last_year,
        COUNT(DISTINCT role_name)               AS distinct_roles,
        AVG(nr_order)                           AS avg_credit_order
    FROM actor_movies
    GROUP BY actor_id, actor_name
),
latest_movie AS (
    SELECT
        actor_id,
        movie_title,
        year,
        role_name,
        ROW_NUMBER() OVER (PARTITION BY actor_id ORDER BY year DESC) AS rn
    FROM actor_movies
)
SELECT
    a.actor_name,
    a.total_movies,
    a.first_year,
    a.last_year,
    a.distinct_roles,
    a.avg_credit_order,
    l.movie_title   AS latest_movie_title,
    l.year          AS latest_movie_year,
    l.role_name     AS latest_role_name
FROM actor_stats AS a
JOIN (
    SELECT actor_id, movie_title, year, role_name
    FROM latest_movie
    WHERE rn = 1
) AS l ON a.actor_id = l.actor_id
ORDER BY a.total_movies DESC
LIMIT 10
