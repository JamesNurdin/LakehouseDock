WITH person_stats AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        n.gender,
        n.imdb_id,
        COUNT(DISTINCT ci.movie_id) AS total_movie_count,
        COUNT(DISTINCT CASE WHEN ci.nr_order <= 5 THEN ci.movie_id END) AS top5_movie_count,
        COUNT(DISTINCT an.id) AS alias_count,
        MAX(CASE WHEN it.info = 'birth date' THEN 1 ELSE 0 END) AS has_birth_date
    FROM name n
    LEFT JOIN cast_info ci ON ci.person_id = n.id
    LEFT JOIN aka_name an ON an.person_id = n.id
    LEFT JOIN person_info pi ON pi.person_id = n.id
    LEFT JOIN info_type it ON pi.info_type_id = it.id
    GROUP BY n.id, n.name, n.gender, n.imdb_id
    HAVING COUNT(DISTINCT ci.movie_id) > 0
)
SELECT
    person_id,
    person_name,
    gender,
    imdb_id,
    total_movie_count,
    top5_movie_count,
    alias_count,
    has_birth_date
FROM person_stats
ORDER BY total_movie_count DESC, top5_movie_count DESC, alias_count DESC
LIMIT 20
