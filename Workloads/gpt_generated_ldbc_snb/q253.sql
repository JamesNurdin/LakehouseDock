WITH forum_base AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date AS forum_creation_date,
        f.moderator_person_id
    FROM forum AS f
),
moderator_info AS (
    SELECT
        fb.forum_id,
        fb.title,
        fb.forum_creation_date,
        p_mod.first_name AS moderator_first_name,
        p_mod.last_name AS moderator_last_name
    FROM forum_base fb
    LEFT JOIN person AS p_mod
        ON fb.moderator_person_id = p_mod.id
),
post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post AS p
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count
    FROM comment AS c
    JOIN post AS p
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
like_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS like_count
    FROM person_likes_post AS plp
    JOIN post AS p
        ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
member_stats AS (
    SELECT
        fhm.forum_id,
        COUNT(DISTINCT fhm.person_id) AS member_count
    FROM forum_has_member_person AS fhm
    GROUP BY fhm.forum_id
)
SELECT
    mi.forum_id,
    mi.title,
    mi.forum_creation_date,
    mi.moderator_first_name,
    mi.moderator_last_name,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(ls.like_count, 0) AS like_count,
    COALESCE(ms.member_count, 0) AS member_count,
    (COALESCE(ps.post_count, 0) + COALESCE(cs.comment_count, 0) + COALESCE(ls.like_count, 0)) AS total_activity
FROM moderator_info mi
LEFT JOIN post_stats ps
    ON mi.forum_id = ps.forum_id
LEFT JOIN comment_stats cs
    ON mi.forum_id = cs.forum_id
LEFT JOIN like_stats ls
    ON mi.forum_id = ls.forum_id
LEFT JOIN member_stats ms
    ON mi.forum_id = ms.forum_id
ORDER BY total_activity DESC
LIMIT 10
