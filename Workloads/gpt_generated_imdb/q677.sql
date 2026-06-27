WITH aka_counts AS (
    SELECT n.id AS person_id,
           COUNT(DISTINCT a.id) AS aka_name_cnt
    FROM name n
    LEFT JOIN aka_name a ON a.person_id = n.id
    GROUP BY n.id
),
info_counts AS (
    SELECT n.id AS person_id,
           COUNT(DISTINCT p.id) AS info_cnt,
           COUNT(DISTINCT p.info_type_id) AS distinct_info_type_cnt
    FROM name n
    LEFT JOIN person_info p ON p.person_id = n.id
    GROUP BY n.id
)
SELECT n.surname_pcode,
       n.gender,
       COUNT(DISTINCT n.id) AS person_cnt,
       SUM(COALESCE(ac.aka_name_cnt, 0)) AS total_aka_names,
       AVG(COALESCE(ac.aka_name_cnt, 0)) AS avg_aka_names_per_person,
       SUM(COALESCE(ic.info_cnt, 0)) AS total_info_entries,
       AVG(COALESCE(ic.info_cnt, 0)) AS avg_info_entries_per_person,
       SUM(COALESCE(ic.distinct_info_type_cnt, 0)) AS total_distinct_info_types,
       AVG(COALESCE(ic.distinct_info_type_cnt, 0)) AS avg_distinct_info_types_per_person
FROM name n
LEFT JOIN aka_counts ac ON ac.person_id = n.id
LEFT JOIN info_counts ic ON ic.person_id = n.id
WHERE n.gender IS NOT NULL
GROUP BY n.surname_pcode, n.gender
ORDER BY n.surname_pcode, n.gender
