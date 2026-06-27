SELECT
    tc.id AS tag_class_id,
    tc.name AS tag_class_name,
    COUNT(DISTINCT p.id) AS post_count,
    AVG(p.length) AS avg_post_length,
    COUNT(DISTINCT f.id) AS forum_with_posts_count,
    COUNT(DISTINCT ft.forum_id) AS forum_with_tags_count,
    COUNT(DISTINCT phi.person_id) AS person_interest_count,
    COUNT(DISTINCT cht.comment_id) AS comment_tag_count
FROM tag_class tc
LEFT JOIN tag t
       ON t.type_tag_class_id = tc.id
LEFT JOIN post_has_tag_tag pt
       ON pt.tag_id = t.id
LEFT JOIN post p
       ON pt.post_id = p.id
LEFT JOIN forum f
       ON p.container_forum_id = f.id
LEFT JOIN forum_has_tag_tag ft
       ON ft.tag_id = t.id
LEFT JOIN person_has_interest_tag phi
       ON phi.tag_id = t.id
LEFT JOIN comment_has_tag_tag cht
       ON cht.tag_id = t.id
GROUP BY tc.id, tc.name
ORDER BY post_count DESC
LIMIT 10
