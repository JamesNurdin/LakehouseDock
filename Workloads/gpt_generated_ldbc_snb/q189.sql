WITH post_likes AS (
    SELECT post_id,
           COUNT(*) AS like_count
    FROM person_likes_post
    GROUP BY post_id
),
post_comments AS (
    SELECT parent_post_id AS post_id,
           COUNT(*) AS comment_count,
           SUM(length) AS sum_comment_length
    FROM comment
    GROUP BY parent_post_id
),
post_tags AS (
    SELECT post_id,
           COUNT(DISTINCT tag_id) AS tag_count
    FROM post_has_tag_tag
    GROUP BY post_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    m.first_name AS moderator_first_name,
    m.last_name AS moderator_last_name,
    COUNT(DISTINCT p.id) AS num_posts,
    COALESCE(SUM(pl.like_count), 0) AS total_likes,
    COALESCE(SUM(pc.comment_count), 0) AS total_comments,
    COALESCE(SUM(pc.sum_comment_length), 0) / NULLIF(SUM(pc.comment_count), 0) AS avg_comment_length,
    COALESCE(AVG(p.length), 0) AS avg_post_length,
    COALESCE(SUM(pt.tag_count), 0) AS total_tags,
    COUNT(DISTINCT p.creator_person_id) AS distinct_creators,
    COALESCE(SUM(pl.like_count), 0) / NULLIF(COUNT(DISTINCT p.id), 0) AS avg_likes_per_post
FROM forum f
JOIN person m ON f.moderator_person_id = m.id
JOIN post p ON p.container_forum_id = f.id
LEFT JOIN post_likes pl ON pl.post_id = p.id
LEFT JOIN post_comments pc ON pc.post_id = p.id
LEFT JOIN post_tags pt ON pt.post_id = p.id
GROUP BY f.id, f.title, m.first_name, m.last_name
ORDER BY avg_likes_per_post DESC
LIMIT 10
