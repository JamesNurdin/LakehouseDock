WITH person_info_counts AS (
    SELECT
        n.id AS person_id,
        n.name AS person_name,
        it.info AS info_type,
        COUNT(pinfo.id) AS info_count
    FROM name n
    JOIN person_info pinfo
        ON pinfo.person_id = n.id
    JOIN info_type it
        ON it.id = pinfo.info_type_id
    GROUP BY n.id, n.name, it.info
),
cast_counts AS (
    SELECT
        n.id AS person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM name n
    JOIN cast_info ci
        ON ci.person_id = n.id
    GROUP BY n.id
)
SELECT
    pic.person_id,
    pic.person_name,
    pic.info_type,
    pic.info_count,
    COALESCE(cc.movie_count, 0) AS movie_count
FROM person_info_counts pic
LEFT JOIN cast_counts cc
    ON cc.person_id = pic.person_id
WHERE pic.info_count > 1
ORDER BY pic.info_count DESC, cc.movie_count DESC
LIMIT 50
