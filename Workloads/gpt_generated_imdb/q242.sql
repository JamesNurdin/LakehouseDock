WITH movie_char_counts AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT cn.id) AS char_count
    FROM cast_info ci
    JOIN title t ON ci.movie_id = t.id
    JOIN char_name cn ON ci.person_role_id = cn.id
    GROUP BY t.id
),
runtime_info AS (
    SELECT
        t.id AS movie_id,
        CAST(mi.info AS DOUBLE) AS runtime_minutes
    FROM movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    JOIN title t ON mi.movie_id = t.id
    WHERE it.info = 'runtime'
)
SELECT
    kt.kind AS kind,
    COUNT(DISTINCT t.id) AS movie_count,
    COUNT(DISTINCT n.id) AS distinct_actor_count,
    AVG(mcc.char_count) AS avg_characters_per_movie,
    AVG(ri.runtime_minutes) AS avg_runtime_minutes
FROM title t
JOIN kind_type kt ON t.kind_id = kt.id
LEFT JOIN cast_info ci ON ci.movie_id = t.id
LEFT JOIN name n ON ci.person_id = n.id
LEFT JOIN movie_char_counts mcc ON mcc.movie_id = t.id
LEFT JOIN runtime_info ri ON ri.movie_id = t.id
WHERE t.production_year >= 2000
GROUP BY kt.kind
ORDER BY distinct_actor_count DESC
LIMIT 5
