WITH alias_counts AS (
    SELECT
        an.person_id,
        COUNT(DISTINCT an.name) AS alias_count
    FROM aka_name an
    GROUP BY an.person_id
),
info_agg AS (
    SELECT
        pi.person_id,
        ARRAY_AGG(DISTINCT pi.info) AS infos
    FROM person_info pi
    GROUP BY pi.person_id
)
SELECT
    n.id,
    n.name,
    n.gender,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    COUNT(DISTINCT cn.id) AS distinct_character_count,
    COALESCE(ac.alias_count, 0) AS alias_count,
    COALESCE(any_value(ia.infos), CAST(ARRAY[] AS array(varchar))) AS infos
FROM name n
LEFT JOIN cast_info ci ON ci.person_id = n.id
LEFT JOIN char_name cn ON ci.person_role_id = cn.id
LEFT JOIN alias_counts ac ON ac.person_id = n.id
LEFT JOIN info_agg ia ON ia.person_id = n.id
WHERE n.gender IS NOT NULL
GROUP BY n.id, n.name, n.gender, ac.alias_count
ORDER BY movie_count DESC, distinct_character_count DESC
LIMIT 10
