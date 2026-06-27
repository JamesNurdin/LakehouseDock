WITH post_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT p.id) AS post_cnt,
        COUNT(DISTINCT p.container_forum_id) AS forum_cnt,
        AVG(p.length) AS avg_post_length
    FROM post p
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    JOIN tag t ON pt.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
forum_member_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT fm.person_id) AS forum_member_cnt
    FROM forum_has_tag_tag ft
    JOIN tag t ON ft.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    JOIN forum_has_member_person fm ON fm.forum_id = ft.forum_id
    GROUP BY tc.id
),
person_interest_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(DISTINCT pit.person_id) AS interested_person_cnt
    FROM person_has_interest_tag pit
    JOIN tag t ON pit.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
),
comment_metrics AS (
    SELECT
        tc.id AS tag_class_id,
        COUNT(*) AS comment_cnt
    FROM comment_has_tag_tag cht
    JOIN tag t ON cht.tag_id = t.id
    JOIN tag_class tc ON t.type_tag_class_id = tc.id
    GROUP BY tc.id
)
SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    COALESCE(pm.post_cnt, 0) AS post_cnt,
    COALESCE(pm.forum_cnt, 0) AS forum_cnt,
    COALESCE(pm.avg_post_length, 0) AS avg_post_length,
    COALESCE(im.forum_member_cnt, 0) AS forum_member_cnt,
    COALESCE(pi.interested_person_cnt, 0) AS interested_person_cnt,
    COALESCE(cm.comment_cnt, 0) AS comment_cnt
FROM tag_class tc
LEFT JOIN post_metrics pm ON pm.tag_class_id = tc.id
LEFT JOIN forum_member_metrics im ON im.tag_class_id = tc.id
LEFT JOIN person_interest_metrics pi ON pi.tag_class_id = tc.id
LEFT JOIN comment_metrics cm ON cm.tag_class_id = tc.id
ORDER BY post_cnt DESC
LIMIT 10
