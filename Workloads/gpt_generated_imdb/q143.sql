WITH person_movie_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        COUNT(DISTINCT ci.movie_id) AS distinct_movie_count,
        COUNT(DISTINCT an.id) AS aka_name_count,
        COUNT(DISTINCT pi.id) AS person_info_count,
        SUM(CASE WHEN it.info = 'Biography' THEN 1 ELSE 0 END) AS biography_info_count,
        COUNT(DISTINCT mi.movie_id) FILTER (WHERE it.info = 'Genre') AS genre_movie_count
    FROM name n
    LEFT JOIN cast_info ci
        ON ci.person_id = n.id
    LEFT JOIN aka_name an
        ON an.person_id = n.id
    LEFT JOIN person_info pi
        ON pi.person_id = n.id
    LEFT JOIN info_type it
        ON it.id = pi.info_type_id
    LEFT JOIN movie_info mi
        ON mi.info_type_id = it.id
    GROUP BY n.id, n.name
)
SELECT
    person_id,
    person_name,
    distinct_movie_count,
    aka_name_count,
    person_info_count,
    biography_info_count,
    genre_movie_count
FROM person_movie_stats
WHERE distinct_movie_count > 0
ORDER BY distinct_movie_count DESC, person_name
LIMIT 50
