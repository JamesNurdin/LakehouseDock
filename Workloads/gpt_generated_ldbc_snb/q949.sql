WITH tag_analytics AS (
    SELECT
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        COUNT(DISTINCT p.id) AS post_count,
        COUNT(DISTINCT pt.post_id) AS post_tag_association_count,
        COUNT(DISTINCT f.id) AS forum_count,
        COUNT(DISTINCT ft.forum_id) AS forum_tag_association_count,
        COUNT(DISTINCT cht.comment_id) AS comment_tag_association_count,
        COUNT(DISTINCT pi.person_id) AS person_interest_tag_association_count
    FROM tag_class tc
    LEFT JOIN tag t
        ON t.type_tag_class_id = tc.id
    LEFT JOIN post_has_tag_tag pt
        ON pt.tag_id = t.id
    LEFT JOIN post p
        ON p.id = pt.post_id
    LEFT JOIN forum_has_tag_tag ft
        ON ft.tag_id = t.id
    LEFT JOIN forum f
        ON f.id = ft.forum_id
    LEFT JOIN comment_has_tag_tag cht
        ON cht.tag_id = t.id
    LEFT JOIN person_has_interest_tag pi
        ON pi.tag_id = t.id
    GROUP BY tc.id, tc.name
)
SELECT
    tag_class_id,
    tag_class_name,
    post_count,
    post_tag_association_count,
    forum_count,
    forum_tag_association_count,
    comment_tag_association_count,
    person_interest_tag_association_count
FROM tag_analytics
ORDER BY post_count DESC
LIMIT 10
