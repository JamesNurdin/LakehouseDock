/*
  Top 10 characters that have been portrayed by the most distinct actors.
  For each character we also count:
    • the number of distinct movies the character appears in,
    • the number of distinct alternate names belonging to those actors,
    • the number of distinct person‑info types recorded for those actors.
  All joins follow the permitted join rules.
*/
WITH char_actor_stats AS (
    SELECT
        cn.id   AS char_id,
        cn.name AS character_name,
        COUNT(DISTINCT n.id)                 AS distinct_actors,
        COUNT(DISTINCT ci.movie_id)          AS distinct_movies,
        COUNT(DISTINCT an.id)                AS distinct_alternate_names,
        COUNT(DISTINCT pi.info_type_id)      AS distinct_person_info_types
    FROM char_name cn
    JOIN cast_info ci
        ON ci.person_role_id = cn.id                -- valid join rule
    JOIN name n
        ON n.id = ci.person_id                      -- valid join rule
    LEFT JOIN aka_name an
        ON an.person_id = n.id                      -- valid join rule
    LEFT JOIN person_info pi
        ON pi.person_id = n.id                      -- valid join rule
    GROUP BY cn.id, cn.name
)
SELECT
    char_id,
    character_name,
    distinct_actors,
    distinct_movies,
    distinct_alternate_names,
    distinct_person_info_types
FROM char_actor_stats
ORDER BY distinct_actors DESC
LIMIT 10
