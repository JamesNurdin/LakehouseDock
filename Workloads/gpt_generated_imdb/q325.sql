/*
  Analytical query: Top 10 actors (by gender) with the most distinct movies released from 2000 onward.
  For each actor we also show:
    • Number of distinct characters played
    • Earliest and latest movie year in the period
    • Count of distinct AKA names recorded for the actor
*/
WITH actor_details AS (
    SELECT
        n.id                         AS actor_id,
        n.name                       AS actor_name,
        n.gender                     AS gender,
        t.id                         AS movie_id,
        t.title                      AS movie_title,
        t.production_year            AS production_year,
        cn.id                        AS character_id,
        cn.name                      AS character_name,
        an.id                        AS aka_id,
        an.name                      AS aka_name,
        pi.id                        AS person_info_id,
        pi.info_type_id              AS info_type_id,
        pi.info                      AS person_info
    FROM cast_info ci
    JOIN name n        ON ci.person_id = n.id               -- join rule 2
    JOIN title t       ON ci.movie_id = t.id                -- join rule 3
    LEFT JOIN char_name cn   ON ci.person_role_id = cn.id   -- join rule 4
    LEFT JOIN aka_name an   ON an.person_id = n.id        -- join rule 1
    LEFT JOIN person_info pi ON pi.person_id = n.id       -- join rule 5
    WHERE t.production_year >= 2000
)
SELECT
    actor_id,
    actor_name,
    gender,
    COUNT(DISTINCT movie_id)        AS distinct_movie_count,
    COUNT(DISTINCT character_id)    AS distinct_character_count,
    MIN(production_year)            AS first_movie_year,
    MAX(production_year)            AS latest_movie_year,
    COUNT(DISTINCT aka_name)        AS distinct_aka_name_count
FROM actor_details
GROUP BY actor_id, actor_name, gender
ORDER BY distinct_movie_count DESC
LIMIT 10
