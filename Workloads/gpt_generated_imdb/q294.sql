WITH actor_movie_stats AS (
    SELECT
        n.id AS actor_id,
        n.name AS actor_name,
        COUNT(DISTINCT t.id) AS total_movies,
        AVG(t.production_year) AS avg_production_year
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY n.id, n.name
),
actor_genre_counts AS (
    SELECT
        n.id AS actor_id,
        COALESCE(it.info, 'Unknown') AS genre,
        COUNT(*) AS genre_count
    FROM cast_info ci
    JOIN name n ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    LEFT JOIN movie_info mi ON mi.movie_id = t.id
    LEFT JOIN info_type it ON mi.info_type_id = it.id AND it.info = 'genre'
    WHERE t.production_year >= 2000
    GROUP BY n.id, COALESCE(it.info, 'Unknown')
),
actor_top_genre AS (
    SELECT
        actor_id,
        genre,
        genre_count
    FROM (
        SELECT
            actor_id,
            genre,
            genre_count,
            ROW_NUMBER() OVER (PARTITION BY actor_id ORDER BY genre_count DESC) AS rn
        FROM actor_genre_counts
    )
    WHERE rn = 1
)
SELECT
    ms.actor_name,
    ms.total_movies,
    ms.avg_production_year,
    tg.genre,
    tg.genre_count
FROM actor_movie_stats ms
JOIN actor_top_genre tg ON ms.actor_id = tg.actor_id
ORDER BY ms.total_movies DESC
LIMIT 20
