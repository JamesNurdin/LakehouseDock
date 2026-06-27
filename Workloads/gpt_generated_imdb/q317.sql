WITH action_movies AS (
    SELECT ci.person_id,
           ci.movie_id,
           t.production_year
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'genre' AND mi.info = 'Action'
)
SELECT n.name AS actor_name,
       COUNT(DISTINCT am.movie_id) AS action_movie_count,
       MIN(am.production_year) AS earliest_year,
       MAX(am.production_year) AS latest_year
FROM action_movies am
JOIN name n ON am.person_id = n.id
GROUP BY n.name
ORDER BY action_movie_count DESC, actor_name
LIMIT 10
