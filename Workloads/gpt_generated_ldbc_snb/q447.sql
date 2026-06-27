SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    m.first_name AS moderator_first_name,
    m.last_name AS moderator_last_name,
    COUNT(DISTINCT p.id) AS post_count,
    COALESCE(SUM(p.length), 0) AS total_post_length,
    COUNT(DISTINCT p.creator_person_id) AS distinct_post_creators,
    COALESCE(SUM(lc.like_cnt), 0) AS total_post_likes,
    COUNT(DISTINCT c.id) AS comment_count,
    COUNT(DISTINCT c.creator_person_id) AS distinct_commenters,
    CASE WHEN COUNT(DISTINCT p.id) = 0 THEN 0
         ELSE COALESCE(SUM(lc.like_cnt), 0) / COUNT(DISTINCT p.id)
    END AS avg_likes_per_post,
    CASE WHEN COUNT(DISTINCT p.id) = 0 THEN 0
         ELSE COUNT(DISTINCT c.id) / COUNT(DISTINCT p.id)
    END AS avg_comments_per_post
FROM forum f
LEFT JOIN person m
    ON m.id = f.moderator_person_id
LEFT JOIN post p
    ON p.container_forum_id = f.id
LEFT JOIN (
    SELECT post_id, COUNT(*) AS like_cnt
    FROM person_likes_post
    GROUP BY post_id
) lc
    ON lc.post_id = p.id
LEFT JOIN comment c
    ON c.parent_post_id = p.id
GROUP BY f.id, f.title, m.first_name, m.last_name
ORDER BY post_count DESC
LIMIT 10
