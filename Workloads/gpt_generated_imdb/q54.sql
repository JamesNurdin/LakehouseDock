WITH cast_size_per_movie AS (
    SELECT
        movie_id,
        count(*) AS cast_size
    FROM cast_info
    GROUP BY movie_id
),
rating_per_movie AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
)
SELECT
    n.id AS actor_id,
    n.name AS actor_name,
    count(DISTINCT t.id) AS num_movies,
    avg(cs.cast_size) AS avg_cast_size,
    min(t.production_year) AS earliest_year,
    max(t.production_year) AS latest_year,
    avg(r.rating) AS avg_rating
FROM name n
JOIN cast_info ci ON ci.person_id = n.id
JOIN title t ON t.id = ci.movie_id
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_size_per_movie cs ON cs.movie_id = t.id
LEFT JOIN rating_per_movie r ON r.movie_id = t.id
WHERE kt.kind = 'movie'
GROUP BY n.id, n.name
ORDER BY num_movies DESC
LIMIT 10
