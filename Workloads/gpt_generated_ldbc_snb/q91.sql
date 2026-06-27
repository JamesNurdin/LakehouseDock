WITH posts_per_forum AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(plp.person_id) AS total_post_likes,
        COUNT(DISTINCT plp.person_id) AS distinct_post_likers
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id
    GROUP BY f.id, f.title
),
comments_per_forum AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(plc.person_id) AS total_comment_likes,
        COUNT(DISTINCT plc.person_id) AS distinct_comment_likers
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY f.id
),
members_per_forum AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY f.id
)
SELECT
    f.forum_id,
    f.forum_title,
    COALESCE(f.post_count, 0) AS post_count,
    COALESCE(f.avg_post_length, 0) AS avg_post_length,
    COALESCE(f.total_post_likes, 0) AS total_post_likes,
    COALESCE(f.distinct_post_likers, 0) AS distinct_post_likers,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_likes, 0) AS total_comment_likes,
    COALESCE(c.distinct_comment_likers, 0) AS distinct_comment_likers,
    COALESCE(m.member_count, 0) AS member_count,
    (COALESCE(f.post_count, 0) + COALESCE(c.comment_count, 0)) AS total_activity
FROM posts_per_forum f
LEFT JOIN comments_per_forum c
    ON c.forum_id = f.forum_id
LEFT JOIN members_per_forum m
    ON m.forum_id = f.forum_id
ORDER BY total_activity DESC
LIMIT 10
