WITH post_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(p.id) AS post_count,
        SUM(p.length) AS total_post_length,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_post_creators
    FROM post p
    GROUP BY p.container_forum_id
),
comment_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(c.id) AS comment_count,
        SUM(c.length) AS total_comment_length,
        AVG(c.length) AS avg_comment_length,
        COUNT(DISTINCT c.creator_person_id) AS distinct_comment_creators
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_like_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(plp.person_id) AS post_like_count,
        COUNT(DISTINCT plp.person_id) AS distinct_post_likers
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_like_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(plc.person_id) AS comment_like_count,
        COUNT(DISTINCT plc.person_id) AS distinct_comment_likers
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    f.creation_date AS forum_creation_date,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.total_post_length, 0) AS total_post_length,
    COALESCE(pm.avg_post_length, 0) AS avg_post_length,
    COALESCE(pm.distinct_post_creators, 0) AS distinct_post_creators,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(cm.total_comment_length, 0) AS total_comment_length,
    COALESCE(cm.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(cm.distinct_comment_creators, 0) AS distinct_comment_creators,
    COALESCE(plm.post_like_count, 0) AS post_like_count,
    COALESCE(plm.distinct_post_likers, 0) AS distinct_post_likers,
    COALESCE(clm.comment_like_count, 0) AS comment_like_count,
    COALESCE(clm.distinct_comment_likers, 0) AS distinct_comment_likers,
    COALESCE(plm.distinct_post_likers, 0) + COALESCE(clm.distinct_comment_likers, 0) AS total_distinct_likers,
    CASE
        WHEN (COALESCE(pm.post_count, 0) + COALESCE(cm.comment_count, 0)) = 0 THEN 0
        ELSE (COALESCE(plm.post_like_count, 0) + COALESCE(clm.comment_like_count, 0)) * 1.0 / (COALESCE(pm.post_count, 0) + COALESCE(cm.comment_count, 0))
    END AS engagement_score
FROM forum f
LEFT JOIN post_metrics pm ON f.id = pm.forum_id
LEFT JOIN comment_metrics cm ON f.id = cm.forum_id
LEFT JOIN post_like_metrics plm ON f.id = plm.forum_id
LEFT JOIN comment_like_metrics clm ON f.id = clm.forum_id
ORDER BY post_count DESC, comment_count DESC
LIMIT 10
