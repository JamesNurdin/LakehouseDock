WITH forum_posts AS (
    SELECT
        p.id AS post_id,
        p.length AS post_length,
        p.container_forum_id AS forum_id
    FROM post p
),
likes_per_post AS (
    SELECT
        pl.post_id,
        COUNT(*) AS like_count
    FROM person_likes_post pl
    GROUP BY pl.post_id
),
comments_per_post AS (
    SELECT
        co.parent_post_id AS post_id,
        COUNT(*) AS comment_count,
        SUM(co.length) AS comment_length_sum
    FROM comment co
    GROUP BY co.parent_post_id
)
SELECT
    f.title AS forum_title,
    mod.first_name AS moderator_first_name,
    mod.last_name AS moderator_last_name,
    COUNT(DISTINCT fp.post_id) AS total_posts,
    COALESCE(SUM(lp.like_count), 0) AS total_likes,
    COALESCE(SUM(cp.comment_count), 0) AS total_comments,
    AVG(fp.post_length) AS avg_post_length,
    CASE
        WHEN COALESCE(SUM(cp.comment_count), 0) = 0 THEN NULL
        ELSE SUM(cp.comment_length_sum) / SUM(cp.comment_count)
    END AS avg_comment_length
FROM forum_posts fp
JOIN forum f
    ON fp.forum_id = f.id
JOIN person mod
    ON f.moderator_person_id = mod.id
LEFT JOIN likes_per_post lp
    ON fp.post_id = lp.post_id
LEFT JOIN comments_per_post cp
    ON fp.post_id = cp.post_id
GROUP BY f.title, mod.first_name, mod.last_name
ORDER BY total_posts DESC
LIMIT 10
