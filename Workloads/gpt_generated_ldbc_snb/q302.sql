WITH tag_counts AS (
    SELECT
        t.type_tag_class_id,
        t.id,
        t.name,
        COUNT(DISTINCT p.person_id) AS person_cnt,
        COUNT(*) AS interest_cnt
    FROM person_has_interest_tag p
    JOIN tag t
        ON p.tag_id = t.id
    GROUP BY t.type_tag_class_id, t.id, t.name
)
SELECT
    type_tag_class_id,
    id AS tag_id,
    name AS tag_name,
    person_cnt,
    interest_cnt,
    (interest_cnt * 1.0 / person_cnt) AS avg_interests_per_person,
    ROW_NUMBER() OVER (PARTITION BY type_tag_class_id ORDER BY interest_cnt DESC) AS rank_within_type
FROM tag_counts
WHERE person_cnt > 10
ORDER BY interest_cnt DESC
LIMIT 20
