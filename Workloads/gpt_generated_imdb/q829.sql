WITH actor_stats AS (
    SELECT
        n.id AS name_id,
        n.name AS actor_name,
        n.gender,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        COUNT(DISTINCT cn.id) AS distinct_characters,
        COUNT(DISTINCT an.id) AS alt_names_count,
        COUNT(DISTINCT CASE WHEN pi.info_type_id = 1 THEN pi.info END) AS info_type1_count
    FROM name n
    LEFT JOIN cast_info ci
        ON ci.person_id = n.id
    LEFT JOIN char_name cn
        ON ci.person_role_id = cn.id
    LEFT JOIN aka_name an
        ON an.person_id = n.id
    LEFT JOIN person_info pi
        ON pi.person_id = n.id
    GROUP BY n.id, n.name, n.gender
)
SELECT
    gender,
    COUNT(*) AS actor_count,
    SUM(movies_count) AS total_movies,
    AVG(movies_count) AS avg_movies_per_actor,
    SUM(distinct_characters) AS total_distinct_characters,
    AVG(distinct_characters) AS avg_characters_per_actor,
    SUM(alt_names_count) AS total_alt_names,
    AVG(alt_names_count) AS avg_alt_names_per_actor,
    SUM(info_type1_count) AS total_info_type1_entries
FROM actor_stats
GROUP BY gender
ORDER BY total_movies DESC
