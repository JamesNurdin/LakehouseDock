WITH actor_movie_details AS (
    SELECT
        n.id AS name_id,
        n.name AS person_name,
        t.id AS title_id,
        mk.keyword_id,
        cn.id AS char_id
    FROM name n
    JOIN cast_info ci ON ci.person_id = n.id
    JOIN title t ON t.id = ci.movie_id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN char_name cn ON cn.id = ci.person_role_id
),
actor_aggregates AS (
    SELECT
        amd.name_id,
        amd.person_name,
        COUNT(DISTINCT amd.title_id) AS movie_count,
        COUNT(DISTINCT amd.keyword_id) AS distinct_keyword_count,
        COUNT(DISTINCT amd.char_id) AS distinct_character_count
    FROM actor_movie_details amd
    GROUP BY amd.name_id, amd.person_name
    HAVING COUNT(DISTINCT amd.title_id) >= 5
),
actor_extra AS (
    SELECT
        a.name_id,
        a.person_name,
        a.movie_count,
        a.distinct_keyword_count,
        a.distinct_character_count,
        COUNT(DISTINCT ak.id) AS aka_name_count,
        COUNT(DISTINCT pi.id) AS person_info_count
    FROM actor_aggregates a
    LEFT JOIN aka_name ak ON ak.person_id = a.name_id
    LEFT JOIN person_info pi ON pi.person_id = a.name_id
    GROUP BY a.name_id, a.person_name, a.movie_count, a.distinct_keyword_count, a.distinct_character_count
)
SELECT
    ae.name_id,
    ae.person_name,
    ae.movie_count,
    ae.distinct_keyword_count,
    ae.distinct_character_count,
    ae.aka_name_count,
    ae.person_info_count,
    RANK() OVER (ORDER BY ae.distinct_keyword_count DESC) AS keyword_rank
FROM actor_extra ae
ORDER BY keyword_rank
LIMIT 10
