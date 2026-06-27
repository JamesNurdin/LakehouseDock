WITH
    forum_posts AS (
        SELECT f.id AS forum_id,
               p.id AS post_id,
               p.length AS post_length,
               p.creator_person_id AS creator_id
        FROM post p
        JOIN forum f ON p.container_forum_id = f.id
    ),
    forum_comments AS (
        SELECT f.id AS forum_id,
               c.id AS comment_id,
               c.length AS comment_length,
               c.creator_person_id AS creator_id
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        JOIN forum f ON p.container_forum_id = f.id
    ),
    post_likes AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*) AS total_post_likes
        FROM person_likes_post plp
        JOIN post p ON plp.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    comment_likes AS (
        SELECT p.container_forum_id AS forum_id,
               COUNT(*) AS total_comment_likes
        FROM person_likes_comment plc
        JOIN comment c ON plc.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    forum_user_creators AS (
        SELECT forum_id, creator_id FROM forum_posts
        UNION
        SELECT forum_id, creator_id FROM forum_comments
    ),
    forum_user_counts AS (
        SELECT forum_id,
               COUNT(DISTINCT creator_id) AS distinct_user_count
        FROM forum_user_creators
        GROUP BY forum_id
    ),
    post_agg AS (
        SELECT forum_id,
               COUNT(DISTINCT post_id) AS total_posts,
               AVG(post_length) AS avg_post_length,
               SUM(post_length) AS sum_post_length
        FROM forum_posts
        GROUP BY forum_id
    ),
    comment_agg AS (
        SELECT forum_id,
               COUNT(DISTINCT comment_id) AS total_comments,
               AVG(comment_length) AS avg_comment_length,
               SUM(comment_length) AS sum_comment_length
        FROM forum_comments
        GROUP BY forum_id
    )
SELECT f.id AS forum_id,
       f.title AS forum_title,
       COALESCE(p.total_posts, 0) AS total_posts,
       COALESCE(c.total_comments, 0) AS total_comments,
       COALESCE(p.avg_post_length, 0) AS avg_post_length,
       COALESCE(c.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(pl.total_post_likes, 0) AS total_post_likes,
       COALESCE(cl.total_comment_likes, 0) AS total_comment_likes,
       COALESCE(u.distinct_user_count, 0) AS distinct_user_count
FROM forum f
LEFT JOIN post_agg p   ON f.id = p.forum_id
LEFT JOIN comment_agg c ON f.id = c.forum_id
LEFT JOIN post_likes pl ON f.id = pl.forum_id
LEFT JOIN comment_likes cl ON f.id = cl.forum_id
LEFT JOIN forum_user_counts u ON f.id = u.forum_id
ORDER BY total_posts DESC
LIMIT 10
