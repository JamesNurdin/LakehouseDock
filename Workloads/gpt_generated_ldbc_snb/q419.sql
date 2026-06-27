WITH
    post_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT p.id) AS post_count,
            COALESCE(SUM(p.length), 0) AS total_post_length,
            AVG(p.length) AS avg_post_length
        FROM post p
        GROUP BY p.container_forum_id
    ),
    comment_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT c.id) AS comment_count,
            COALESCE(SUM(c.length), 0) AS total_comment_length,
            AVG(c.length) AS avg_comment_length
        FROM comment c
        JOIN post p
            ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    post_likes_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT plp.person_id) AS post_likes_count
        FROM person_likes_post plp
        JOIN post p
            ON plp.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    comment_likes_stats AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(DISTINCT plc.person_id) AS comment_likes_count
        FROM person_likes_comment plc
        JOIN comment c
            ON plc.comment_id = c.id
        JOIN post p
            ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
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
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.total_post_length, 0) AS total_post_length,
    ps.avg_post_length,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.total_comment_length, 0) AS total_comment_length,
    cs.avg_comment_length,
    COALESCE(pls.post_likes_count, 0) AS post_likes_count,
    COALESCE(cls.comment_likes_count, 0) AS comment_likes_count,
    COALESCE(ms.member_count, 0) AS member_count
FROM forum f
LEFT JOIN post_stats ps
    ON ps.forum_id = f.id
LEFT JOIN comment_stats cs
    ON cs.forum_id = f.id
LEFT JOIN post_likes_stats pls
    ON pls.forum_id = f.id
LEFT JOIN comment_likes_stats cls
    ON cls.forum_id = f.id
LEFT JOIN member_stats ms
    ON ms.forum_id = f.id
ORDER BY post_count DESC
LIMIT 10
