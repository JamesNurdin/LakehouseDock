WITH actor_awards AS (
    SELECT
        n.id AS actor_id,
        COUNT(DISTINCT pi.id) AS award_count
    FROM name n
    JOIN person_info pi ON pi.person_id = n.id
    JOIN info_type it ON pi.info_type_id = it.id
    WHERE it.info = 'award'
    GROUP BY n.id
)
SELECT
    n.id AS actor_id,
    n.name AS actor_name,
    COUNT(DISTINCT t.id) AS movie_count,
    COUNT(DISTINCT cn.id) AS character_count,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    COALESCE(MAX(a.award_count), 0) AS award_count
FROM name n
JOIN cast_info ci ON ci.person_id = n.id
JOIN title t ON ci.movie_id = t.id
LEFT JOIN char_name cn ON ci.person_role_id = cn.id
LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN actor_awards a ON a.actor_id = n.id
WHERE t.production_year >= 2000
GROUP BY n.id, n.name
ORDER BY movie_count DESC
LIMIT 10
