WITH
    forum_mod AS (
        SELECT
            f.id AS forum_id,
            f.title AS forum_title,
            p.first_name AS moderator_first_name,
            p.last_name AS moderator_last_name
        FROM forum AS f
        JOIN person AS p
            ON f.moderator_person_id = p.id
    ),
    forum_members AS (
        SELECT
            fm.forum_id,
            COUNT(DISTINCT fm.person_id) AS member_count
        FROM forum_has_member_person AS fm
        GROUP BY fm.forum_id
    ),
    post_agg AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT po.id) AS post_count,
            AVG(po.length) AS avg_post_length,
            COALESCE(SUM(lc.like_cnt), 0) AS total_post_likes
        FROM forum AS f
        JOIN post AS po
            ON po.container_forum_id = f.id
        LEFT JOIN (
            SELECT
                plp.post_id,
                COUNT(*) AS like_cnt
            FROM person_likes_post AS plp
            GROUP BY plp.post_id
        ) AS lc
            ON po.id = lc.post_id
        GROUP BY f.id
    ),
    comment_agg AS (
        SELECT
            f.id AS forum_id,
            COUNT(DISTINCT co.id) AS comment_count,
            AVG(co.length) AS avg_comment_length,
            COALESCE(SUM(lc.like_cnt), 0) AS total_comment_likes
        FROM forum AS f
        JOIN post AS po
            ON po.container_forum_id = f.id
        JOIN comment AS co
            ON co.parent_post_id = po.id
        LEFT JOIN (
            SELECT
                plc.comment_id,
                COUNT(*) AS like_cnt
            FROM person_likes_comment AS plc
            GROUP BY plc.comment_id
        ) AS lc
            ON co.id = lc.comment_id
        GROUP BY f.id
    )
SELECT
    fm.forum_id,
    fm.forum_title,
    fm.moderator_first_name,
    fm.moderator_last_name,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(p.post_count, 0) AS post_count,
    p.avg_post_length,
    p.total_post_likes,
    COALESCE(c.comment_count, 0) AS comment_count,
    c.avg_comment_length,
    c.total_comment_likes,
    (p.total_post_likes + c.total_comment_likes) AS total_interactions
FROM forum_mod AS fm
LEFT JOIN forum_members AS m
    ON fm.forum_id = m.forum_id
LEFT JOIN post_agg AS p
    ON fm.forum_id = p.forum_id
LEFT JOIN comment_agg AS c
    ON fm.forum_id = c.forum_id
ORDER BY total_interactions DESC
LIMIT 10
