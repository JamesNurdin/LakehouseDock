WITH actor_movies AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        t.id AS movie_id,
        it.info AS genre,
        cn.name AS character_name
    FROM
        name n
        JOIN cast_info ci ON ci.person_id = n.id
        JOIN title t ON ci.movie_id = t.id
        LEFT JOIN movie_info mi ON mi.movie_id = t.id
        LEFT JOIN info_type it ON mi.info_type_id = it.id AND it.info = 'genre'
        LEFT JOIN char_name cn ON ci.person_role_id = cn.id
    WHERE
        t.production_year >= 2000
),
aka_counts AS (
    SELECT
        an.person_id,
        COUNT(*) AS aka_name_count
    FROM
        aka_name an
    GROUP BY
        an.person_id
)
SELECT
    am.person_id,
    am.person_name,
    COUNT(DISTINCT am.movie_id) AS movie_count,
    COUNT(DISTINCT am.genre) AS distinct_genre_count,
    COUNT(DISTINCT am.character_name) AS distinct_character_count,
    COALESCE(ac.aka_name_count, 0) AS aka_name_count
FROM
    actor_movies am
    LEFT JOIN aka_counts ac ON ac.person_id = am.person_id
GROUP BY
    am.person_id,
    am.person_name,
    ac.aka_name_count
HAVING
    COUNT(DISTINCT am.movie_id) >= 5
ORDER BY
    movie_count DESC
LIMIT 10
