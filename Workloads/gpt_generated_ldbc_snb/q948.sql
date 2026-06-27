WITH post_likes AS (
    SELECT
        pl.post_id,
        COUNT(*) AS post_like_cnt
    FROM person_likes_post pl
    GROUP BY pl.post_id
),
comment_likes AS (
    SELECT
        cl.comment_id,
        COUNT(*) AS comment_like_cnt
    FROM person_likes_comment cl
    GROUP BY cl.comment_id
),
forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        f.creation_date AS forum_creation_date,
        COUNT(DISTINCT fm.person_id) AS member_cnt,
        COUNT(DISTINCT ft.tag_id) AS tag_cnt,
        COUNT(DISTINCT p.id) AS post_cnt,
        AVG(p.length) AS avg_post_length,
        COALESCE(SUM(pl.post_like_cnt), 0) AS total_post_likes,
        COALESCE(SUM(cl.comment_like_cnt), 0) AS total_comment_likes,
        COUNT(DISTINCT c.id) AS comment_cnt,
        mod.gender AS moderator_gender
    FROM forum f
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    LEFT JOIN forum_has_tag_tag ft
        ON ft.forum_id = f.id
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN post_likes pl
        ON pl.post_id = p.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN comment_likes cl
        ON cl.comment_id = c.id
    LEFT JOIN person mod
        ON f.moderator_person_id = mod.id
    GROUP BY f.id, f.title, f.creation_date, mod.gender
)
SELECT
    forum_id,
    forum_title,
    forum_creation_date,
    member_cnt,
    tag_cnt,
    post_cnt,
    avg_post_length,
    total_post_likes,
    total_comment_likes,
    comment_cnt,
    moderator_gender,
    CASE WHEN post_cnt > 0 THEN total_post_likes / CAST(post_cnt AS double) END AS avg_likes_per_post,
    CASE WHEN comment_cnt > 0 THEN total_comment_likes / CAST(comment_cnt AS double) END AS avg_likes_per_comment,
    CASE WHEN post_cnt > 0 THEN comment_cnt / CAST(post_cnt AS double) END AS avg_comments_per_post
FROM forum_stats
ORDER BY (total_post_likes + total_comment_likes) DESC
LIMIT 100
