WITH forum_info AS (
    SELECT 
        f.id AS forum_id,
        f.title AS forum_title,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name
    FROM forum f
    JOIN person mod
        ON f.moderator_person_id = mod.id
),
posts_agg AS (
    SELECT 
        f.forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM forum_info f
    JOIN post p
        ON p.container_forum_id = f.forum_id
    GROUP BY f.forum_id
),
comments_agg AS (
    SELECT 
        f.forum_id,
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(DISTINCT c.creator_person_id) AS distinct_commenters
    FROM forum_info f
    JOIN post p
        ON p.container_forum_id = f.forum_id
    JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY f.forum_id
),
likes_agg AS (
    SELECT 
        f.forum_id,
        COUNT(DISTINCT pl.person_id) AS like_count
    FROM forum_info f
    JOIN post p
        ON p.container_forum_id = f.forum_id
    JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY f.forum_id
),
tags_agg AS (
    SELECT 
        f.forum_id,
        COUNT(DISTINCT pt.tag_id) AS tag_count
    FROM forum_info f
    JOIN post p
        ON p.container_forum_id = f.forum_id
    JOIN post_has_tag_tag pt
        ON pt.post_id = p.id
    GROUP BY f.forum_id
)
SELECT 
    f.forum_id,
    f.forum_title,
    f.moderator_first_name,
    f.moderator_last_name,
    p.post_count,
    p.avg_post_length,
    c.comment_count,
    c.distinct_commenters,
    l.like_count,
    t.tag_count,
    CASE WHEN p.post_count > 0 THEN l.like_count / p.post_count ELSE NULL END AS likes_per_post,
    CASE WHEN c.comment_count > 0 THEN l.like_count / c.comment_count ELSE NULL END AS likes_per_comment
FROM forum_info f
LEFT JOIN posts_agg p ON p.forum_id = f.forum_id
LEFT JOIN comments_agg c ON c.forum_id = f.forum_id
LEFT JOIN likes_agg l ON l.forum_id = f.forum_id
LEFT JOIN tags_agg t ON t.forum_id = f.forum_id
ORDER BY l.like_count DESC
LIMIT 10
