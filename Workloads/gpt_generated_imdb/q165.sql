WITH genre_movies AS (
    SELECT
        t.id AS movie_id,
        mi.info AS genre
    FROM title t
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'genres'
      AND t.production_year >= 2000
),
actor_genre_counts AS (
    SELECT
        gm.genre,
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_appearances
    FROM genre_movies gm
    JOIN cast_info ci ON ci.movie_id = gm.movie_id
    GROUP BY gm.genre, ci.person_id
),
ranked_actors AS (
    SELECT
        genre,
        person_id,
        movie_appearances,
        ROW_NUMBER() OVER (PARTITION BY genre ORDER BY movie_appearances DESC) AS rn
    FROM actor_genre_counts
)
SELECT
    r.genre,
    n.name AS actor_name,
    r.movie_appearances
FROM ranked_actors r
JOIN name n ON n.id = r.person_id
WHERE r.rn <= 5
ORDER BY r.genre, r.movie_appearances DESC
