WITH aka_counts AS (
    SELECT
        a.person_id,
        COUNT(*) AS aka_name_count
    FROM aka_name a
    GROUP BY a.person_id
),
person_info_counts AS (
    SELECT
        pi.person_id,
        it.info AS info_type,
        COUNT(*) AS info_count
    FROM person_info pi
    JOIN info_type it ON pi.info_type_id = it.id
    GROUP BY pi.person_id, it.info
)
SELECT
    n.id,
    n.name,
    n.gender,
    COALESCE(ac.aka_name_count, 0) AS aka_name_count,
    pic.info_type,
    pic.info_count
FROM name n
LEFT JOIN aka_counts ac ON ac.person_id = n.id
LEFT JOIN person_info_counts pic ON pic.person_id = n.id
WHERE n.gender IS NOT NULL
ORDER BY n.id, pic.info_type
