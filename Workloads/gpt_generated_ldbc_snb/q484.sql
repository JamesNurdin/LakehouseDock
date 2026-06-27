WITH member_counts AS (
    SELECT
        forum_id,
        COUNT(DISTINCT person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_id
),
post_stats AS (
    SELECT
        container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(length) AS avg_post_length,
        COUNT(DISTINCT language) AS distinct_post_languages
    FROM post
    GROUP BY container_forum_id
),
comment_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
like_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT pl.person_id) AS like_count
    FROM person_likes_post pl
    JOIN post p ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_mod AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        f.moderator_person_id
    FROM forum f
),
moderator_names AS (
    SELECT
        person.id AS moderator_id,
        person.first_name,
        person.last_name
    FROM person
)
SELECT
    fm.forum_id,
    fm.forum_title,
    mn.first_name AS moderator_first_name,
    mn.last_name AS moderator_last_name,
    COALESCE(mc.member_count, 0) AS member_count,
    COALESCE(ps.post_count, 0) AS post_count,
    ps.avg_post_length,
    COALESCE(cs.comment_count, 0) AS comment_count,
    cs.avg_comment_length,
    COALESCE(ls.like_count, 0) AS like_count,
    ps.distinct_post_languages
FROM forum_mod fm
LEFT JOIN moderator_names mn ON mn.moderator_id = fm.moderator_person_id
LEFT JOIN member_counts mc ON mc.forum_id = fm.forum_id
LEFT JOIN post_stats ps ON ps.forum_id = fm.forum_id
LEFT JOIN comment_stats cs ON cs.forum_id = fm.forum_id
LEFT JOIN like_stats ls ON ls.forum_id = fm.forum_id
ORDER BY member_count DESC
LIMIT 10
