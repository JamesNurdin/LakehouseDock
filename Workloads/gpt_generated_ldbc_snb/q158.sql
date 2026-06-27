WITH tag_persons AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        t.type_tag_class_id,
        p.person_id,
        CAST(p.creation_date AS DATE) AS creation_date
    FROM person_has_interest_tag p
    JOIN tag t
        ON p.tag_id = t.id
    WHERE t.name LIKE 'A%'
)
SELECT
    tag_id,
    tag_name,
    type_tag_class_id,
    COUNT(DISTINCT person_id) AS distinct_person_count,
    MIN(creation_date) AS earliest_creation_date,
    MAX(creation_date) AS latest_creation_date
FROM tag_persons
GROUP BY tag_id, tag_name, type_tag_class_id
ORDER BY distinct_person_count DESC
LIMIT 10
