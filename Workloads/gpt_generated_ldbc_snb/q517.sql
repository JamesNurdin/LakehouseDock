WITH forum_members AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    LEFT JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    GROUP BY f.id
),
forum_tags AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT ft.tag_id) AS tag_count
    FROM forum f
    LEFT JOIN forum_has_tag_tag ft
        ON ft.forum_id = f.id
    GROUP BY f.id
),
forum_posts AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT p.id) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    GROUP BY f.id
),
forum_comments AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    GROUP BY f.id
),
forum_post_likes AS (
    SELECT f.id AS forum_id,
           COUNT(plp.person_id) AS post_like_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person_likes_post plp
        ON plp.post_id = p.id
    GROUP BY f.id
),
forum_comment_likes AS (
    SELECT f.id AS forum_id,
           COUNT(plc.person_id) AS comment_like_count
    FROM forum f
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN comment c
        ON c.parent_post_id = p.id
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY f.id
)
SELECT f.id AS forum_id,
       f.title,
       f.creation_date,
       COALESCE(m.member_count, 0) AS member_count,
       COALESCE(t.tag_count, 0) AS tag_count,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(p.avg_post_length, 0) AS avg_post_length,
       COALESCE(c.comment_count, 0) AS comment_count,
       COALESCE(c.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(pl.post_like_count, 0) AS post_like_count,
       COALESCE(cl.comment_like_count, 0) AS comment_like_count
FROM forum f
LEFT JOIN forum_members m      ON m.forum_id = f.id
LEFT JOIN forum_tags t          ON t.forum_id = f.id
LEFT JOIN forum_posts p         ON p.forum_id = f.id
LEFT JOIN forum_comments c      ON c.forum_id = f.id
LEFT JOIN forum_post_likes pl   ON pl.forum_id = f.id
LEFT JOIN forum_comment_likes cl ON cl.forum_id = f.id
ORDER BY f.creation_date DESC
LIMIT 100
