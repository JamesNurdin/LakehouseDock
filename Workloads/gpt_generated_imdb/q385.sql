WITH rating AS (
    SELECT
        mi.movie_id,
        CAST(mi.info AS double) AS rating
    FROM movie_info mi
    JOIN info_type it
        ON mi.info_type_id = it.id
    WHERE it.info = 'rating'
),
actor_movie_stats AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        COUNT(DISTINCT t.id) AS movie_count,
        AVG(r.rating) AS avg_rating
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    JOIN title t
        ON ci.movie_id = t.id
    JOIN kind_type kt
        ON t.kind_id = kt.id
    LEFT JOIN rating r
        ON r.movie_id = t.id
    WHERE kt.kind = 'movie'
    GROUP BY n.id, n.name
),
actor_keyword_stats AS (
    SELECT
        n.id AS actor_id,
        COUNT(DISTINCT mk.keyword_id) AS distinct_keyword_count
    FROM cast_info ci
    JOIN name n
        ON ci.person_id = n.id
    JOIN title t
        ON ci.movie_id = t.id
    JOIN kind_type kt
        ON t.kind_id = kt.id
    JOIN movie_keyword mk
        ON mk.movie_id = t.id
    WHERE kt.kind = 'movie'
    GROUP BY n.id
)
SELECT
    ams.actor_name,
    ams.movie_count,
    ams.avg_rating,
    aks.distinct_keyword_count
FROM actor_movie_stats ams
LEFT JOIN actor_keyword_stats aks
    ON ams.actor_id = aks.actor_id
ORDER BY ams.movie_count DESC, ams.avg_rating DESC
LIMIT 10
