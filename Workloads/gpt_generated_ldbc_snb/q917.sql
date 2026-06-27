WITH forum_members AS (
    SELECT
        f.id AS forum_id,
        f.title,
        COUNT(DISTINCT fp.person_id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fp ON fp.forum_id = f.id
    GROUP BY f.id, f.title
),
post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
post_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(plp.person_id) AS post_like_count
    FROM post p
    JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
comment_stats AS (
    SELECT
        po.container_forum_id AS forum_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post po ON c.parent_post_id = po.id
    GROUP BY po.container_forum_id
),
comment_likes AS (
    SELECT
        po.container_forum_id AS forum_id,
        COUNT(plc.person_id) AS comment_like_count
    FROM comment c
    JOIN post po ON c.parent_post_id = po.id
    JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY po.container_forum_id
)
SELECT
    fm.forum_id,
    fm.title,
    fm.member_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length,
    COALESCE(pl.post_like_count, 0) AS post_like_count,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(cl.comment_like_count, 0) AS comment_like_count
FROM forum_members fm
LEFT JOIN post_stats ps ON ps.forum_id = fm.forum_id
LEFT JOIN post_likes pl ON pl.forum_id = fm.forum_id
LEFT JOIN comment_stats cs ON cs.forum_id = fm.forum_id
LEFT JOIN comment_likes cl ON cl.forum_id = fm.forum_id
ORDER BY fm.member_count DESC
LIMIT 10
