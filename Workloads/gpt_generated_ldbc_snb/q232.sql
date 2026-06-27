WITH post_metrics AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        COUNT(plp.person_id) AS post_like_count
    FROM post
    LEFT JOIN person_likes_post plp
        ON plp.post_id = post.id
    GROUP BY post.container_forum_id
),
comment_metrics AS (
    SELECT
        post.container_forum_id AS forum_id,
        COUNT(DISTINCT comment.id) AS comment_count,
        COUNT(plc.person_id) AS comment_like_count,
        AVG(comment.length) AS avg_comment_length
    FROM post
    LEFT JOIN comment
        ON comment.parent_post_id = post.id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = comment.id
    GROUP BY post.container_forum_id
),
forum_participants AS (
    SELECT
        forum_id,
        COUNT(DISTINCT participant_id) AS participant_count
    FROM (
        SELECT
            post.container_forum_id AS forum_id,
            post.creator_person_id AS participant_id
        FROM post
        UNION ALL
        SELECT
            p.container_forum_id AS forum_id,
            comment.creator_person_id AS participant_id
        FROM comment
        JOIN post p
            ON comment.parent_post_id = p.id
    ) participants
    GROUP BY forum_id
)
SELECT
    f.id AS forum_id,
    f.title,
    p_mod.first_name AS moderator_first_name,
    p_mod.last_name AS moderator_last_name,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(pm.post_like_count, 0) AS post_like_count,
    COALESCE(cm.comment_like_count, 0) AS comment_like_count,
    COALESCE(cm.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(fp.participant_count, 0) AS participant_count
FROM forum f
LEFT JOIN person p_mod
    ON f.moderator_person_id = p_mod.id
LEFT JOIN post_metrics pm
    ON pm.forum_id = f.id
LEFT JOIN comment_metrics cm
    ON cm.forum_id = f.id
LEFT JOIN forum_participants fp
    ON fp.forum_id = f.id
ORDER BY (COALESCE(pm.post_like_count, 0) + COALESCE(cm.comment_like_count, 0)) DESC
LIMIT 10
