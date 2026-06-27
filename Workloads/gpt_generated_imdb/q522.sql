/* Top 10 primary names with the most alternate (aka) names */
WITH person_aka_counts AS (
    SELECT
        name.id,
        name.name,
        name.gender,
        COUNT(aka_name.id) AS aka_count,
        COUNT(DISTINCT aka_name.name) AS distinct_aka_names
    FROM name
    LEFT JOIN aka_name
        ON aka_name.person_id = name.id
    GROUP BY name.id, name.name, name.gender
)
SELECT
    id AS person_id,
    name AS primary_name,
    gender,
    aka_count,
    distinct_aka_names,
    ROW_NUMBER() OVER (ORDER BY aka_count DESC) AS rank_by_aka_count
FROM person_aka_counts
WHERE aka_count > 0
ORDER BY aka_count DESC
LIMIT 10
