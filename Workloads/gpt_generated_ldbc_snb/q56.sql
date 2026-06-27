WITH
    members AS (
        SELECT
            fhmp.forum_id,
            COUNT(DISTINCT fhmp.person_id) AS member_count
        FROM forum_has_member_person fhmp
        GROUP BY fhmp.forum_id
    ),
    posts AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS post_count
        FROM post p
        GROUP BY p.container_forum_id
    ),
    comments AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS comment_count,
            AVG(c.length) AS avg_comment_length
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    ),
    post_likes AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS post_like_count
        FROM person_likes_post plp
        JOIN post p ON plp.post_id = p.id
        GROUP BY p.container_forum_id
    ),
    comment_likes AS (
        SELECT
            p.container_forum_id AS forum_id,
            COUNT(*) AS comment_like_count
        FROM person_likes_comment plc
        JOIN comment c ON plc.comment_id = c.id
        JOIN post p ON c.parent_post_id = p.id
        GROUP BY p.container_forum_id
    )
SELECT
    f.id AS forum_id,
    f.title,
    f.creation_date,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(pst.post_count, 0) AS post_count,
    COALESCE(cmt.comment_count, 0) AS comment_count,
    COALESCE(cmt.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(pl.post_like_count, 0) AS post_like_count,
    COALESCE(cl.comment_like_count, 0) AS comment_like_count
FROM forum f
LEFT JOIN members m ON f.id = m.forum_id
LEFT JOIN posts pst ON f.id = pst.forum_id
LEFT JOIN comments cmt ON f.id = cmt.forum_id
LEFT JOIN post_likes pl ON f.id = pl.forum_id
LEFT JOIN comment_likes cl ON f.id = cl.forum_id
ORDER BY member_count DESC, forum_id
