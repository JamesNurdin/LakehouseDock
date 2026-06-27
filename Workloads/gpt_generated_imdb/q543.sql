/*
  Top 10 actors/actresses by the number of distinct movies they appear in,
  together with counts of their alternate names (aka_name) and whether a
  birthdate entry exists in person_info.
*/
WITH movie_counts AS (
    SELECT ci.person_id AS person_id,
           COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM cast_info ci
    GROUP BY ci.person_id
),
aka_counts AS (
    SELECT an.person_id AS person_id,
           COUNT(DISTINCT an.name) AS aka_name_count
    FROM aka_name an
    GROUP BY an.person_id
),
birthdate_counts AS (
    SELECT pi.person_id AS person_id,
           COUNT(*) AS birthdate_info_count
    FROM person_info pi
    JOIN info_type it ON pi.info_type_id = it.id
    WHERE it.info = 'birthdate'
    GROUP BY pi.person_id
)
SELECT
    n.id AS person_id,
    n.name,
    COALESCE(mc.movie_count, 0)      AS movie_count,
    COALESCE(ac.aka_name_count, 0)   AS aka_name_count,
    COALESCE(bc.birthdate_info_count, 0) AS birthdate_info_count
FROM name n
LEFT JOIN movie_counts mc   ON mc.person_id = n.id   -- cast_info.person_id = name.id
LEFT JOIN aka_counts   ac   ON ac.person_id = n.id   -- aka_name.person_id = name.id
LEFT JOIN birthdate_counts bc ON bc.person_id = n.id   -- person_info.person_id = name.id
ORDER BY movie_count DESC, n.name
LIMIT 10
