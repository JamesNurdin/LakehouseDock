WITH person_aka_counts AS (
    SELECT
        n.id AS person_id,
        n.name AS primary_name,
        n.gender,
        COUNT(a.id) AS aka_name_count
    FROM name n
    LEFT JOIN aka_name a
        ON a.person_id = n.id
    WHERE n.gender IN ('M', 'F')
    GROUP BY n.id, n.name, n.gender
)
SELECT
    person_id,
    primary_name,
    gender,
    aka_name_count,
    RANK() OVER (PARTITION BY gender ORDER BY aka_name_count DESC) AS gender_rank
FROM person_aka_counts
WHERE aka_name_count >= 5
ORDER BY gender, gender_rank
LIMIT 20
