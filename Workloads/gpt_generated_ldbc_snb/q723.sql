WITH forum_base AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        f.creation_date AS forum_creation_date,
        f.moderator_person_id
    FROM forum f
),
moderator_info AS (
    SELECT
        p.id AS moderator_id,
        p.first_name AS moderator_first_name,
        p.last_name AS moderator_last_name
    FROM person p
),
forum_moderators AS (
    SELECT
        fb.forum_id,
        fb.forum_title,
        fb.forum_creation_date,
        mi.moderator_first_name,
        mi.moderator_last_name
    FROM forum_base fb
    JOIN moderator_info mi
        ON fb.moderator_person_id = mi.moderator_id
),
member_counts AS (
    SELECT
        fmp.forum_id,
        COUNT(DISTINCT fmp.person_id) AS member_count
    FROM forum_has_member_person fmp
    GROUP BY fmp.forum_id
),
post_counts AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count
    FROM post p
    GROUP BY p.container_forum_id
),
comment_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
like_metrics AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS like_count,
        COUNT(DISTINCT plp.person_id) AS distinct_liker_count
    FROM person_likes_post plp
    JOIN post p
        ON plp.post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT
    fm.forum_id,
    fm.forum_title,
    fm.forum_creation_date,
    fm.moderator_first_name,
    fm.moderator_last_name,
    COALESCE(mc.member_count, 0) AS member_count,
    COALESCE(pc.post_count, 0) AS post_count,
    COALESCE(cm.comment_count, 0) AS comment_count,
    cm.avg_comment_length,
    CASE WHEN pc.post_count > 0 THEN cm.comment_count / pc.post_count END AS comment_per_post_ratio,
    COALESCE(lm.like_count, 0) AS like_count,
    COALESCE(lm.distinct_liker_count, 0) AS distinct_liker_count
FROM forum_moderators fm
LEFT JOIN member_counts mc
    ON fm.forum_id = mc.forum_id
LEFT JOIN post_counts pc
    ON fm.forum_id = pc.forum_id
LEFT JOIN comment_metrics cm
    ON fm.forum_id = cm.forum_id
LEFT JOIN like_metrics lm
    ON fm.forum_id = lm.forum_id
ORDER BY post_count DESC
LIMIT 10
