WITH actor_basic_stats AS (
    SELECT
        n.id AS person_id,
        n.name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        COUNT(DISTINCT an.id) AS aka_name_count,
        COUNT(DISTINCT pi.info_type_id) AS person_info_type_count
    FROM name n
    LEFT JOIN cast_info ci ON ci.person_id = n.id
    LEFT JOIN aka_name an ON an.person_id = n.id
    LEFT JOIN person_info pi ON pi.person_id = n.id
    GROUP BY n.id, n.name, n.gender
),
actor_genre_counts AS (
    SELECT
        n.id AS person_id,
        mi.info AS genre,
        COUNT(DISTINCT ci.movie_id) AS genre_movie_count
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN movie_info mi ON mi.movie_id = t.id
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE it.info = 'genre'
    GROUP BY n.id, mi.info
),
actor_top_genre AS (
    SELECT
        person_id,
        genre,
        genre_movie_count,
        ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY genre_movie_count DESC) AS rn
    FROM actor_genre_counts
),
actor_combined AS (
    SELECT
        bs.person_id,
        bs.name,
        bs.gender,
        bs.movie_count,
        bs.aka_name_count,
        bs.person_info_type_count,
        tg.genre AS top_genre,
        tg.genre_movie_count AS top_genre_movie_count
    FROM actor_basic_stats bs
    LEFT JOIN actor_top_genre tg
        ON tg.person_id = bs.person_id AND tg.rn = 1
)
SELECT
    person_id,
    name,
    gender,
    movie_count,
    aka_name_count,
    person_info_type_count,
    top_genre,
    top_genre_movie_count
FROM actor_combined
WHERE movie_count > 0
ORDER BY movie_count DESC
LIMIT 100
