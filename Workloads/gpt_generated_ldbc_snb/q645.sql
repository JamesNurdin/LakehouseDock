WITH tag_usage AS (
    SELECT tag_id, 'comment' AS usage_type FROM comment_has_tag_tag
    UNION ALL
    SELECT tag_id, 'post' AS usage_type FROM post_has_tag_tag
    UNION ALL
    SELECT tag_id, 'forum' AS usage_type FROM forum_has_tag_tag
),

tag_usage_agg AS (
    SELECT
        tag_id,
        COUNT(*) AS total_usages,
        SUM(CASE WHEN usage_type = 'comment' THEN 1 ELSE 0 END) AS comment_usages,
        SUM(CASE WHEN usage_type = 'post' THEN 1 ELSE 0 END) AS post_usages,
        SUM(CASE WHEN usage_type = 'forum' THEN 1 ELSE 0 END) AS forum_usages
    FROM tag_usage
    GROUP BY tag_id
),

person_interest_agg AS (
    SELECT
        pit.tag_id,
        COUNT(DISTINCT pit.person_id) AS person_interest_count,
        SUM(CASE WHEN p.gender = 'male' THEN 1 ELSE 0 END) AS male_interest,
        SUM(CASE WHEN p.gender = 'female' THEN 1 ELSE 0 END) AS female_interest
    FROM person_has_interest_tag pit
    JOIN person p ON pit.person_id = p.id
    GROUP BY pit.tag_id
),

tag_details AS (
    SELECT
        t.id AS tag_id,
        t.name AS tag_name,
        t.type_tag_class_id,
        tc.name AS tag_class_name,
        parent_tc.name AS parent_tag_class_name
    FROM tag t
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    LEFT JOIN tag_class parent_tc ON tc.subclass_of_tag_class_id = parent_tc.id
)
SELECT
    td.tag_class_name,
    td.parent_tag_class_name,
    td.tag_name,
    COALESCE(tua.total_usages, 0) AS total_usages,
    COALESCE(tua.comment_usages, 0) AS comment_usages,
    COALESCE(tua.post_usages, 0) AS post_usages,
    COALESCE(tua.forum_usages, 0) AS forum_usages,
    COALESCE(pia.person_interest_count, 0) AS person_interest_count,
    COALESCE(pia.male_interest, 0) AS male_interest,
    COALESCE(pia.female_interest, 0) AS female_interest
FROM tag_details td
LEFT JOIN tag_usage_agg tua ON td.tag_id = tua.tag_id
LEFT JOIN person_interest_agg pia ON td.tag_id = pia.tag_id
ORDER BY total_usages DESC
LIMIT 100
