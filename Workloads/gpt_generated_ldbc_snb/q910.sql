WITH likes_per_post AS (
    SELECT
        post_id,
        COUNT(*) AS like_count
    FROM person_likes_post
    GROUP BY post_id
),
comments_per_post AS (
    SELECT
        parent_post_id AS post_id,
        COUNT(*) AS comment_count,
        SUM(length) AS comment_length_sum
    FROM comment
    WHERE parent_post_id IS NOT NULL
    GROUP BY parent_post_id
),
tags_per_post AS (
    SELECT
        post_id,
        COUNT(*) AS tag_count
    FROM post_has_tag_tag
    GROUP BY post_id
),
forum_posts AS (
    SELECT
        p.id AS post_id,
        p.container_forum_id AS forum_id,
        p.length AS post_length
    FROM post AS p
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    mod_person.first_name AS moderator_first_name,
    mod_person.last_name AS moderator_last_name,
    COUNT(DISTINCT fp.post_id) AS total_posts,
    COALESCE(SUM(lp.like_count), 0) AS total_likes,
    COALESCE(SUM(cp.comment_count), 0) AS total_comments,
    AVG(fp.post_length) AS avg_post_length,
    CASE WHEN SUM(cp.comment_count) > 0 THEN SUM(cp.comment_length_sum) / SUM(cp.comment_count) END AS avg_comment_length,
    COALESCE(SUM(tp.tag_count), 0) / NULLIF(COUNT(DISTINCT fp.post_id), 0) AS avg_tags_per_post
FROM forum AS f
JOIN forum_posts AS fp ON fp.forum_id = f.id
LEFT JOIN likes_per_post AS lp ON lp.post_id = fp.post_id
LEFT JOIN comments_per_post AS cp ON cp.post_id = fp.post_id
LEFT JOIN tags_per_post AS tp ON tp.post_id = fp.post_id
LEFT JOIN person AS mod_person ON f.moderator_person_id = mod_person.id
GROUP BY
    f.id,
    f.title,
    mod_person.first_name,
    mod_person.last_name
ORDER BY total_posts DESC
LIMIT 10
