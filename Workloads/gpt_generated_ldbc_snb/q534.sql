WITH forum_base AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person mod ON f.moderator_person_id = mod.id
),
member_counts AS (
    SELECT
        fhmp.forum_id,
        COUNT(DISTINCT fhmp.person_id) AS member_count
    FROM forum_has_member_person fhmp
    GROUP BY fhmp.forum_id
),
post_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
comment_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
post_like_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT plp.person_id) AS distinct_post_likers
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_like_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT plc.person_id) AS distinct_comment_likers
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT
    fb.forum_id,
    fb.forum_title,
    fb.moderator_first_name,
    fb.moderator_last_name,
    COALESCE(mc.member_count, 0) AS member_count,
    COALESCE(pm.post_count, 0) AS post_count,
    pm.avg_post_length,
    COALESCE(cm.comment_count, 0) AS comment_count,
    cm.avg_comment_length,
    COALESCE(plm.distinct_post_likers, 0) AS distinct_post_likers,
    COALESCE(clm.distinct_comment_likers, 0) AS distinct_comment_likers
FROM forum_base fb
LEFT JOIN member_counts mc ON mc.forum_id = fb.forum_id
LEFT JOIN post_metrics pm ON pm.forum_id = fb.forum_id
LEFT JOIN comment_metrics cm ON cm.forum_id = fb.forum_id
LEFT JOIN post_like_metrics plm ON plm.forum_id = fb.forum_id
LEFT JOIN comment_like_metrics clm ON clm.forum_id = fb.forum_id
ORDER BY member_count DESC
LIMIT 50
