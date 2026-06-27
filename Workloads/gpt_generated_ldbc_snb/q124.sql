WITH forum_member_comment_likes AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        tc.name AS tag_class_name,
        plc.person_id AS liker_id,
        c.id AS comment_id
    FROM forum f
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    JOIN person p_creator
        ON p_creator.id = fm.person_id
    JOIN comment c
        ON c.creator_person_id = p_creator.id
    JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    JOIN comment_has_tag_tag ct
        ON ct.comment_id = c.id
    JOIN tag t
        ON t.id = ct.tag_id
    JOIN tag_class tc
        ON tc.id = t.type_tag_class_id
)
SELECT
    forum_id,
    forum_title,
    tag_class_name,
    COUNT(*) AS likes_count
FROM forum_member_comment_likes
GROUP BY forum_id, forum_title, tag_class_name
ORDER BY likes_count DESC
LIMIT 10
