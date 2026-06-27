WITH tag_person_counts AS (
    SELECT
        t.type_tag_class_id,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(pht.person_id) AS person_count,
        COUNT(DISTINCT pht.person_id) AS distinct_persons,
        MIN(pht.creation_date) AS earliest_creation
    FROM person_has_interest_tag pht
    JOIN tag t
        ON pht.tag_id = t.id
    GROUP BY t.type_tag_class_id, t.id, t.name
)
SELECT
    type_tag_class_id,
    tag_id,
    tag_name,
    person_count,
    distinct_persons,
    earliest_creation,
    ROW_NUMBER() OVER (PARTITION BY type_tag_class_id ORDER BY person_count DESC) AS tag_rank_within_type
FROM tag_person_counts
WHERE person_count > 5
ORDER BY type_tag_class_id, tag_rank_within_type
LIMIT 20
