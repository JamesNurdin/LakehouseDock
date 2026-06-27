WITH tag_class_hierarchy AS (
    SELECT 
        tc.id AS tag_class_id,
        tc.name AS tag_class_name,
        parent.id AS parent_tag_class_id,
        parent.name AS parent_tag_class_name
    FROM tag_class tc
    LEFT JOIN tag_class parent
        ON tc.subclass_of_tag_class_id = parent.id
)
SELECT 
    tch.tag_class_name,
    COUNT(DISTINCT t.id) AS num_tags,
    COUNT(DISTINCT p.id) AS num_persons_interested,
    COUNT(DISTINCT c.comment_id) AS num_comments_tagged,
    COUNT(DISTINCT f.forum_id) AS num_forums_tagged,
    COUNT(DISTINCT po.post_id) AS num_posts_tagged
FROM tag_class_hierarchy tch
LEFT JOIN tag t
    ON t.type_tag_class_id = tch.tag_class_id
LEFT JOIN person_has_interest_tag pi
    ON pi.tag_id = t.id
LEFT JOIN person p
    ON p.id = pi.person_id
LEFT JOIN comment_has_tag_tag c
    ON c.tag_id = t.id
LEFT JOIN forum_has_tag_tag f
    ON f.tag_id = t.id
LEFT JOIN post_has_tag_tag po
    ON po.tag_id = t.id
GROUP BY tch.tag_class_name
ORDER BY num_tags DESC
