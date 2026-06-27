WITH runtime_per_movie AS (
    SELECT mi.movie_id,
           CAST(regexp_extract(mi.info, '(\\d+)', 1) AS integer) AS runtime_minutes
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'runtime'
),
actor_movie_data AS (
    SELECT ci.person_id,
           ci.movie_id,
           r.runtime_minutes,
           mk.keyword_id
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN runtime_per_movie r ON t.id = r.movie_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    WHERE kt.kind = 'movie'
)
SELECT n.name AS actor_name,
       COUNT(DISTINCT am.movie_id) AS total_movies,
       AVG(DISTINCT am.runtime_minutes) AS avg_runtime_minutes,
       COUNT(DISTINCT am.keyword_id) AS distinct_keywords
FROM actor_movie_data am
JOIN name n ON am.person_id = n.id
GROUP BY n.name
HAVING COUNT(DISTINCT am.movie_id) >= 5
ORDER BY total_movies DESC, avg_runtime_minutes DESC
LIMIT 10
