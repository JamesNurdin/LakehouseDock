WITH forum_mod AS (
    SELECT
        f.id AS forum_id,
        f.title,
        mod.id AS moderator_id,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name,
        mod.gender AS moderator_gender
    FROM forum AS f
    JOIN person AS mod
        ON f.moderator_person_id = mod.id
),
forum_member_counts AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person AS fm
    GROUP BY fm.forum_id
),
forum_comment_stats AS (
    SELECT
        f.id AS forum_id,
        COUNT(*) AS total_comments,
        COUNT(DISTINCT c.creator_person_id) AS distinct_commenters,
        AVG(c.length) AS avg_comment_length,
        SUM(CASE WHEN c.parent_comment_id IS NULL THEN 1 ELSE 0 END) AS top_level_comments,
        SUM(CASE WHEN c.parent_comment_id IS NOT NULL THEN 1 ELSE 0 END) AS reply_comments
    FROM forum AS f
    JOIN forum_has_member_person AS fm
        ON fm.forum_id = f.id
    JOIN person AS p
        ON fm.person_id = p.id
    JOIN comment AS c
        ON c.creator_person_id = p.id
    GROUP BY f.id
)
SELECT
    fm.forum_id,
    fm.title,
    fm.moderator_first_name,
    fm.moderator_last_name,
    fm.moderator_gender,
    mc.member_count,
    COALESCE(cs.total_comments, 0) AS total_comments,
    COALESCE(cs.distinct_commenters, 0) AS distinct_commenters,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(cs.top_level_comments, 0) AS top_level_comments,
    COALESCE(cs.reply_comments, 0) AS reply_comments
FROM forum_mod AS fm
JOIN forum_member_counts AS mc
    ON mc.forum_id = fm.forum_id
LEFT JOIN forum_comment_stats AS cs
    ON cs.forum_id = fm.forum_id
ORDER BY mc.member_count DESC, fm.forum_id
