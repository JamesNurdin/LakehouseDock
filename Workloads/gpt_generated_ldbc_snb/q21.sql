WITH forum_tag_counts AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT f.id) AS forum_count,
        COUNT(DISTINCT fht.tag_id) AS forum_tag_distinct_count
    FROM forum_has_tag_tag fht
    JOIN tag t ON fht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN forum f ON fht.forum_id = f.id
    WHERE fht.creation_date >= '2022-01-01'
    GROUP BY tc.id, tc.name
),
person_interest_counts AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT pht.person_id) AS person_interest_count,
        COUNT(DISTINCT pht.tag_id) AS person_tag_distinct_count
    FROM person_has_interest_tag pht
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    WHERE pht.creation_date >= '2022-01-01'
    GROUP BY tc.id
),
post_tag_counts AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT pht.tag_id) AS post_tag_distinct_count
    FROM post_has_tag_tag pht
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    WHERE pht.creation_date >= '2022-01-01'
    GROUP BY tc.id
)
SELECT
    ftc.tag_class_id,
    ftc.tag_class_name,
    ftc.forum_count,
    ftc.forum_tag_distinct_count,
    COALESCE(pic.person_interest_count, 0) AS person_interest_count,
    COALESCE(pic.person_tag_distinct_count, 0) AS person_tag_distinct_count,
    COALESCE(ptc.post_tag_distinct_count, 0) AS post_tag_distinct_count
FROM forum_tag_counts ftc
LEFT JOIN person_interest_counts pic ON ftc.tag_class_id = pic.tag_class_id
LEFT JOIN post_tag_counts ptc ON ftc.tag_class_id = ptc.tag_class_id
ORDER BY ftc.forum_count DESC
LIMIT 20
