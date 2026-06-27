WITH person_alias_info AS (
    SELECT
        n.id AS person_id,
        COUNT(DISTINCT an.id) AS alias_count,
        COUNT(DISTINCT pi.id) AS info_count
    FROM name n
    LEFT JOIN aka_name an ON an.person_id = n.id
    LEFT JOIN person_info pi ON pi.person_id = n.id
    GROUP BY n.id
),
person_movie_role AS (
    SELECT
        n.id AS person_id,
        n.gender AS gender,
        t.production_year AS production_year,
        CASE WHEN t.production_year IS NOT NULL THEN floor(t.production_year / 10) * 10 END AS decade,
        t.id AS movie_id,
        cn.id AS character_id
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN title t ON ci.movie_id = t.id
    JOIN char_name cn ON ci.person_role_id = cn.id
)
SELECT
    pmr.decade,
    pmr.gender,
    COUNT(DISTINCT pmr.person_id) AS distinct_actors,
    COUNT(DISTINCT pmr.movie_id) AS distinct_movies,
    COUNT(DISTINCT pmr.character_id) AS distinct_characters,
    AVG(COALESCE(pai.alias_count, 0)) AS avg_aliases_per_actor,
    AVG(COALESCE(pai.info_count, 0)) AS avg_info_entries_per_actor
FROM person_movie_role pmr
LEFT JOIN person_alias_info pai ON pai.person_id = pmr.person_id
WHERE pmr.decade IS NOT NULL
GROUP BY pmr.decade, pmr.gender
ORDER BY pmr.decade, pmr.gender
