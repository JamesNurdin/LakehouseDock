/* Analytical query: activity metrics per tag class (comments, posts, forums, and person interests) */
WITH comment_counts AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(*) AS comment_cnt
    FROM comment_has_tag_tag cht
    JOIN comment c ON cht.comment_id = c.id
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
post_counts AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(*) AS post_cnt
    FROM post_has_tag_tag pht
    JOIN tag t ON pht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
forum_counts AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(*) AS forum_cnt
    FROM forum_has_tag_tag fht
    JOIN tag t ON fht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
person_interest_counts AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT phit.person_id) AS person_interest_cnt
    FROM person_has_interest_tag phit
    JOIN tag t ON phit.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
)
SELECT
    tc.name AS tag_class_name,
    COALESCE(cc.comment_cnt, 0) AS comment_count,
    COALESCE(pc.post_cnt, 0) AS post_count,
    COALESCE(fc.forum_cnt, 0) AS forum_count,
    COALESCE(pic.person_interest_cnt, 0) AS person_interest_count,
    COALESCE(cc.comment_cnt, 0) + COALESCE(pc.post_cnt, 0) + COALESCE(fc.forum_cnt, 0) AS total_activity
FROM tag_class tc
LEFT JOIN comment_counts cc ON cc.tag_class_id = tc.id
LEFT JOIN post_counts pc ON pc.tag_class_id = tc.id
LEFT JOIN forum_counts fc ON fc.tag_class_id = tc.id
LEFT JOIN person_interest_counts pic ON pic.tag_class_id = tc.id
ORDER BY total_activity DESC
LIMIT 20
