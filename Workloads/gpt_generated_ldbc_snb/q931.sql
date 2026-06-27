WITH forum_members AS (
    SELECT
        fhmp.forum_id,
        COUNT(DISTINCT fhmp.person_id) AS member_count
    FROM forum_has_member_person AS fhmp
    GROUP BY fhmp.forum_id
),
forum_posts AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post AS p
    GROUP BY p.container_forum_id
),
forum_post_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_like_count
    FROM post AS p
    JOIN person_likes_post AS plp
        ON p.id = plp.post_id
    GROUP BY p.container_forum_id
),
forum_comments AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count
    FROM comment AS c
    JOIN post AS p
        ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_comment_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_like_count
    FROM comment AS c
    JOIN post AS p
        ON c.parent_post_id = p.id
    JOIN person_likes_comment AS plc
        ON c.id = plc.comment_id
    GROUP BY p.container_forum_id
)
SELECT
    f.id AS forum_id,
    f.title,
    f.creation_date,
    COALESCE(fp.post_count, 0) AS post_count,
    COALESCE(fc.comment_count, 0) AS comment_count,
    COALESCE(fp.avg_post_length, 0) AS avg_post_length,
    COALESCE(fm.member_count, 0) AS member_count,
    COALESCE(fpl.post_like_count, 0) AS post_like_count,
    COALESCE(fcl.comment_like_count, 0) AS comment_like_count
FROM forum AS f
LEFT JOIN forum_members AS fm
    ON f.id = fm.forum_id
LEFT JOIN forum_posts AS fp
    ON f.id = fp.forum_id
LEFT JOIN forum_post_likes AS fpl
    ON f.id = fpl.forum_id
LEFT JOIN forum_comments AS fc
    ON f.id = fc.forum_id
LEFT JOIN forum_comment_likes AS fcl
    ON f.id = fcl.forum_id
ORDER BY post_count DESC, comment_count DESC
LIMIT 100
