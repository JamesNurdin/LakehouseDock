WITH action_cast AS (
    SELECT ci.person_id AS actor_id,
           ci.movie_id   AS movie_id,
           n.name        AS actor_name,
           an.id         AS aka_id
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    LEFT JOIN aka_name an ON an.person_id = n.id
    WHERE kt.kind = 'movie'
      AND it.info = 'genre'
      AND lower(mi.info) = 'action'
      AND t.production_year BETWEEN 2000 AND 2020
)
SELECT actor_id,
       actor_name,
       COUNT(DISTINCT movie_id) AS total_action_movies,
       COUNT(DISTINCT aka_id)   AS total_aka_names
FROM action_cast
GROUP BY actor_id, actor_name
ORDER BY total_action_movies DESC, total_aka_names DESC
LIMIT 10
