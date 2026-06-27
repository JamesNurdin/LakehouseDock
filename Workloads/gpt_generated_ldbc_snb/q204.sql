WITH tag_counts AS (
    SELECT
        t.type_tag_class_id,
        t.id AS tag_id,
        t.name AS tag_name,
        COUNT(DISTINCT pht.person_id) AS distinct_persons,
        MIN(pht.creation_date) AS earliest_creation_date
    FROM person_has_interest_tag pht
    JOIN tag t ON pht.tag_id = t.id
    GROUP BY t.type_tag_class_id, t.id, t.name
)
SELECT
    tc.type_tag_class_id,
    tc.tag_name,
    tc.distinct_persons,
    tc.earliest_creation_date,
    ROW_NUMBER() OVER (PARTITION BY tc.type_tag_class_id ORDER BY tc.distinct_persons DESC) AS rank_within_type
FROM tag_counts tc
WHERE tc.distinct_persons > 0
ORDER BY tc.type_tag_class_id, rank_within_type
LIMIT 20
