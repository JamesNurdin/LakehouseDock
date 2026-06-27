WITH tag_gender_counts AS (
    SELECT
        p.gender,
        pit.tag_id,
        COUNT(DISTINCT p.id) AS distinct_persons,
        COUNT(pit.tag_id) AS total_assignments
    FROM person AS p
    JOIN person_has_interest_tag AS pit
        ON pit.person_id = p.id
    WHERE p.gender IS NOT NULL
    GROUP BY p.gender, pit.tag_id
)
SELECT
    gender,
    tag_id,
    distinct_persons,
    total_assignments,
    total_assignments * 1.0 / NULLIF(distinct_persons, 0) AS avg_assignments_per_person
FROM tag_gender_counts
ORDER BY distinct_persons DESC
LIMIT 20
