WITH forum_comment_likes AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        c.id AS comment_id,
        c.length AS comment_length,
        plc.person_id AS liker_id
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    JOIN forum f ON p.container_forum_id = f.id
    JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    JOIN tag t ON cht.tag_id = t.id
    JOIN forum_has_tag_tag fht ON fht.forum_id = f.id AND fht.tag_id = t.id
    JOIN person creator ON c.creator_person_id = creator.id
    JOIN forum_has_member_person fmp ON fmp.forum_id = f.id AND fmp.person_id = creator.id
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    WHERE c.length > 100
)
SELECT
    forum_id,
    forum_title,
    COUNT(DISTINCT comment_id) AS total_comments,
    AVG(comment_length) AS avg_comment_length,
    COUNT(liker_id) AS total_likes
FROM forum_comment_likes
GROUP BY forum_id, forum_title
ORDER BY total_likes DESC
LIMIT 10
