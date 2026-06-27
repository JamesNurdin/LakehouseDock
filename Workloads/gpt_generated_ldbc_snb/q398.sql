WITH tag_counts AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT pht.post_id) AS post_count,
        COUNT(DISTINCT cht.comment_id) AS comment_count,
        COUNT(DISTINCT fht.forum_id) AS forum_count,
        COUNT(DISTINCT pit.person_id) AS person_interest_count,
        COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM tag_class tc
    LEFT JOIN tag t ON t.type_tag_class_id = tc.id
    LEFT JOIN post_has_tag_tag pht ON pht.tag_id = t.id
    LEFT JOIN comment_has_tag_tag cht ON cht.tag_id = t.id
    LEFT JOIN forum_has_tag_tag fht ON fht.tag_id = t.id
    LEFT JOIN person_has_interest_tag pit ON pit.tag_id = t.id
    GROUP BY tc.id, tc.name
)
SELECT
    tag_class_id,
    tag_class_name,
    post_count,
    comment_count,
    forum_count,
    person_interest_count,
    distinct_tag_count
FROM tag_counts
ORDER BY post_count DESC, comment_count DESC
LIMIT 100
