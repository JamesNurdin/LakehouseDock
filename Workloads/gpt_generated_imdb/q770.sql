/* Analytical query: Person statistics including alternate names and info entries */
WITH person_stats AS (
    SELECT
        n.id AS person_id,
        n.name,
        n.gender,
        COUNT(DISTINCT a.id) AS alt_name_count,
        COUNT(DISTINCT pi.id) AS person_info_count,
        COUNT(DISTINCT pi.info_type_id) AS distinct_info_type_count,
        (COUNT(DISTINCT a.id) + COUNT(DISTINCT pi.id)) AS total_counts
    FROM name n
    LEFT JOIN aka_name a ON a.person_id = n.id
    LEFT JOIN person_info pi ON pi.person_id = n.id
    GROUP BY n.id, n.name, n.gender
)
SELECT
    person_id,
    name,
    gender,
    alt_name_count,
    person_info_count,
    distinct_info_type_count,
    total_counts
FROM person_stats
WHERE total_counts > 0
ORDER BY total_counts DESC
LIMIT 20
