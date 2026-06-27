/*
   Analytical query: For each forum compute the number of posts, number of comments,
   total likes on posts, total likes on comments, average post length, average comment length,
   and the most frequently used tag within the forum.
*/
WITH
    -- Posts per forum with average post length
    post_stats AS (
        SELECT
            post.container_forum_id AS forum_id,
            COUNT(DISTINCT post.id) AS post_count,
            AVG(post.length) AS avg_post_len
        FROM post
        GROUP BY post.container_forum_id
    ),
    -- Likes on posts per forum
    post_likes AS (
        SELECT
            post.container_forum_id AS forum_id,
            COUNT(*) AS post_like_count
        FROM person_likes_post
        JOIN post
            ON person_likes_post.post_id = post.id
        GROUP BY post.container_forum_id
    ),
    -- Comments per forum with average comment length
    comment_stats AS (
        SELECT
            post.container_forum_id AS forum_id,
            COUNT(DISTINCT comment.id) AS comment_count,
            AVG(comment.length) AS avg_comment_len
        FROM comment
        JOIN post
            ON comment.parent_post_id = post.id
        GROUP BY post.container_forum_id
    ),
    -- Likes on comments per forum
    comment_likes AS (
        SELECT
            post.container_forum_id AS forum_id,
            COUNT(*) AS comment_like_count
        FROM person_likes_comment
        JOIN comment
            ON person_likes_comment.comment_id = comment.id
        JOIN post
            ON comment.parent_post_id = post.id
        GROUP BY post.container_forum_id
    ),
    -- Tag usage per forum
    tag_counts AS (
        SELECT
            post.container_forum_id AS forum_id,
            post_has_tag_tag.tag_id AS tag_id,
            COUNT(*) AS tag_post_count
        FROM post_has_tag_tag
        JOIN post
            ON post_has_tag_tag.post_id = post.id
        GROUP BY post.container_forum_id, post_has_tag_tag.tag_id
    ),
    -- Top tag per forum (break ties arbitrarily)
    top_tag AS (
        SELECT
            forum_id,
            tag_id,
            tag_post_count
        FROM (
            SELECT
                forum_id,
                tag_id,
                tag_post_count,
                ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY tag_post_count DESC) AS rn
            FROM tag_counts
        )
        WHERE rn = 1
    )
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(p.post_count, 0) AS total_posts,
    COALESCE(p.avg_post_len, 0) AS avg_post_length,
    COALESCE(c.comment_count, 0) AS total_comments,
    COALESCE(c.avg_comment_len, 0) AS avg_comment_length,
    COALESCE(pl.post_like_count, 0) AS total_post_likes,
    COALESCE(cl.comment_like_count, 0) AS total_comment_likes,
    tt.tag_id AS top_tag_id,
    tt.tag_post_count AS top_tag_post_count
FROM forum f
LEFT JOIN post_stats p
    ON p.forum_id = f.id
LEFT JOIN comment_stats c
    ON c.forum_id = f.id
LEFT JOIN post_likes pl
    ON pl.forum_id = f.id
LEFT JOIN comment_likes cl
    ON cl.forum_id = f.id
LEFT JOIN top_tag tt
    ON tt.forum_id = f.id
ORDER BY total_posts DESC
