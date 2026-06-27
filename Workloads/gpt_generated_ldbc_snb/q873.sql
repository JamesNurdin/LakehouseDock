WITH post_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(p.id) AS post_count,
        SUM(p.length) AS total_post_length,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
post_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(pl.person_id) AS total_post_likes,
        COUNT(DISTINCT pl.person_id) AS distinct_post_likers
    FROM post p
    LEFT JOIN person_likes_post pl
        ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(c.id) AS comment_count
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
comment_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(cl.person_id) AS total_comment_likes,
        COUNT(DISTINCT cl.person_id) AS distinct_comment_likers
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment cl
        ON cl.comment_id = c.id
    GROUP BY p.container_forum_id
),
creator_stats AS (
    SELECT
        forum_id,
        COUNT(DISTINCT creator_id) AS participant_user_count
    FROM (
        SELECT
            p.container_forum_id AS forum_id,
            p.creator_person_id AS creator_id
        FROM post p
        UNION ALL
        SELECT
            p.container_forum_id AS forum_id,
            c.creator_person_id AS creator_id
        FROM comment c
        JOIN post p
            ON c.parent_post_id = p.id
    ) u
    GROUP BY forum_id
),
member_stats AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person fm
    GROUP BY fm.forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.total_post_length, 0) AS total_post_length,
    COALESCE(pm.avg_post_length, 0) AS avg_post_length,
    COALESCE(pl.total_post_likes, 0) AS total_post_likes,
    COALESCE(pl.distinct_post_likers, 0) AS distinct_post_likers,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(cl.total_comment_likes, 0) AS total_comment_likes,
    COALESCE(cl.distinct_comment_likers, 0) AS distinct_comment_likers,
    COALESCE(ms.member_count, 0) AS member_count,
    COALESCE(cs.participant_user_count, 0) AS participant_user_count
FROM forum f
LEFT JOIN post_metrics pm
    ON pm.forum_id = f.id
LEFT JOIN post_likes pl
    ON pl.forum_id = f.id
LEFT JOIN comment_metrics cm
    ON cm.forum_id = f.id
LEFT JOIN comment_likes cl
    ON cl.forum_id = f.id
LEFT JOIN creator_stats cs
    ON cs.forum_id = f.id
LEFT JOIN member_stats ms
    ON ms.forum_id = f.id
ORDER BY post_count DESC
LIMIT 10
