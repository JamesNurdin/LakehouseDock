WITH alt_counts AS (
    SELECT person_id,
           COUNT(*) AS alt_name_cnt
    FROM aka_name
    GROUP BY person_id
),
info_counts AS (
    SELECT person_id,
           COUNT(DISTINCT info_type_id) AS info_type_cnt
    FROM person_info
    GROUP BY person_id
)
SELECT
    n.gender,
    COUNT(DISTINCT n.id) AS total_persons,
    COALESCE(SUM(ac.alt_name_cnt), 0) / COUNT(DISTINCT n.id) AS avg_alt_names_per_person,
    COALESCE(SUM(ic.info_type_cnt), 0) / COUNT(DISTINCT n.id) AS avg_info_types_per_person
FROM name n
LEFT JOIN alt_counts ac ON ac.person_id = n.id
LEFT JOIN info_counts ic ON ic.person_id = n.id
WHERE n.gender IS NOT NULL
GROUP BY n.gender
ORDER BY n.gender
