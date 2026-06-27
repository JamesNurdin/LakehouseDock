/*
  Analytical query: activity summary per forum
  - Number of members
  - Number of posts and average post length
  - Total likes on posts
  - Number of comments and average comment length
  - Total likes on comments
  - Moderator name
  Results are ordered by member count (descending) then post count.
*/
WITH forum_base AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name
    FROM forum AS f
    LEFT JOIN person AS mod
        ON f.moderator_person_id = mod.id
),
member_counts AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum_has_member_person AS fm
    GROUP BY fm.forum_id
),
post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COALESCE(SUM(lc.like_count), 0) AS post_like_count
    FROM post AS p
    LEFT JOIN (
        SELECT
            post_id,
            COUNT(*) AS like_count
        FROM person_likes_post
        GROUP BY post_id
    ) AS lc
        ON lc.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length,
        COALESCE(SUM(lc.like_count), 0) AS comment_like_count
    FROM comment AS c
    JOIN post AS p
        ON c.parent_post_id = p.id
    LEFT JOIN (
        SELECT
            comment_id,
            COUNT(*) AS like_count
        FROM person_likes_comment
        GROUP BY comment_id
    ) AS lc
        ON lc.comment_id = c.id
    GROUP BY p.container_forum_id
)
SELECT
    fb.forum_id,
    fb.title,
    fb.creation_date,
    fb.moderator_first_name,
    fb.moderator_last_name,
    COALESCE(mc.member_count, 0) AS member_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(ps.post_like_count, 0) AS post_like_count,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(cs.comment_like_count, 0) AS comment_like_count
FROM forum_base AS fb
LEFT JOIN member_counts AS mc
    ON mc.forum_id = fb.forum_id
LEFT JOIN post_stats AS ps
    ON ps.forum_id = fb.forum_id
LEFT JOIN comment_stats AS cs
    ON cs.forum_id = fb.forum_id
ORDER BY member_count DESC, post_count DESC
LIMIT 20
