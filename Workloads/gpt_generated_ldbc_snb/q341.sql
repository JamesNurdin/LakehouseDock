WITH forum_base AS (
    SELECT id AS forum_id,
           title,
           creation_date
    FROM forum
),
forum_members AS (
    SELECT forum_id,
           COUNT(DISTINCT person_id) AS member_count
    FROM forum_has_member_person
    GROUP BY forum_id
),
forum_posts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post p
    WHERE p.creation_date >= '2020-01-01'
    GROUP BY p.container_forum_id
),
forum_post_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_like_count
    FROM post p
    JOIN person_likes_post plp
        ON plp.post_id = p.id
    WHERE p.creation_date >= '2020-01-01'
    GROUP BY p.container_forum_id
),
forum_comments AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM post p
    JOIN comment c
        ON c.parent_post_id = p.id
    WHERE p.creation_date >= '2020-01-01'
      AND c.creation_date >= '2020-01-01'
    GROUP BY p.container_forum_id
),
forum_comment_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_like_count
    FROM post p
    JOIN comment c
        ON c.parent_post_id = p.id
    JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    WHERE p.creation_date >= '2020-01-01'
      AND c.creation_date >= '2020-01-01'
    GROUP BY p.container_forum_id
)
SELECT
    f.forum_id,
    f.title,
    f.creation_date,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(pst.post_count, 0) AS post_count,
    COALESCE(pst.avg_post_length, 0) AS avg_post_length,
    COALESCE(pl.post_like_count, 0) AS post_like_count,
    COALESCE(cmt.comment_count, 0) AS comment_count,
    COALESCE(cmt.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(cl.comment_like_count, 0) AS comment_like_count
FROM forum_base f
LEFT JOIN forum_members m
    ON m.forum_id = f.forum_id
LEFT JOIN forum_posts pst
    ON pst.forum_id = f.forum_id
LEFT JOIN forum_post_likes pl
    ON pl.forum_id = f.forum_id
LEFT JOIN forum_comments cmt
    ON cmt.forum_id = f.forum_id
LEFT JOIN forum_comment_likes cl
    ON cl.forum_id = f.forum_id
ORDER BY member_count DESC, post_count DESC
LIMIT 10
