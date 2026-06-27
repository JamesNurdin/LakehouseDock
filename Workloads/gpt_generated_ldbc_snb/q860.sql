WITH likes_per_post AS (
    SELECT
        post_id,
        COUNT(*) AS like_count
    FROM person_likes_post
    GROUP BY post_id
),
comments_per_post AS (
    SELECT
        cmt.parent_post_id AS post_id,
        COUNT(*) AS comment_count,
        AVG(cmt.length) AS avg_comment_length
    FROM comment cmt
    GROUP BY cmt.parent_post_id
),
tags_per_post AS (
    SELECT
        post_id,
        COUNT(DISTINCT tag_id) AS tag_count
    FROM post_has_tag_tag
    GROUP BY post_id
),
post_details AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        p.id AS post_id,
        p.creation_date AS post_creation_date,
        COALESCE(l.like_count, 0) AS like_count,
        COALESCE(c.comment_count, 0) AS comment_count,
        COALESCE(t.tag_count, 0) AS tag_count,
        COALESCE(c.avg_comment_length, 0) AS avg_comment_length
    FROM forum f
    JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN likes_per_post l
        ON l.post_id = p.id
    LEFT JOIN comments_per_post c
        ON c.post_id = p.id
    LEFT JOIN tags_per_post t
        ON t.post_id = p.id
)
SELECT
    forum_id,
    forum_title,
    post_id,
    post_creation_date,
    like_count,
    comment_count,
    tag_count,
    avg_comment_length
FROM (
    SELECT
        forum_id,
        forum_title,
        post_id,
        post_creation_date,
        like_count,
        comment_count,
        tag_count,
        avg_comment_length,
        ROW_NUMBER() OVER (PARTITION BY forum_id ORDER BY like_count DESC, comment_count DESC) AS rn
    FROM post_details
) sub
WHERE rn <= 5
ORDER BY forum_id, rn
