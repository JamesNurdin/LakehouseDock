WITH forum_members AS (
    SELECT fhm.forum_id,
           COUNT(DISTINCT fhm.person_id) AS member_count
    FROM forum_has_member_person fhm
    GROUP BY fhm.forum_id
),
forum_posts AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
forum_post_tags AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(DISTINCT pht.tag_id) AS distinct_post_tag_count
    FROM post p
    JOIN post_has_tag_tag pht ON p.id = pht.post_id
    GROUP BY p.container_forum_id
),
forum_tags AS (
    SELECT fht.forum_id,
           COUNT(DISTINCT fht.tag_id) AS distinct_forum_tag_count
    FROM forum_has_tag_tag fht
    GROUP BY fht.forum_id
),
forum_comments AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_count
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_post_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_like_count
    FROM person_likes_post plp
    JOIN post p ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_comment_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_like_count
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT f.id,
       f.title,
       COALESCE(m.member_count, 0)               AS member_count,
       COALESCE(p.post_count, 0)                 AS post_count,
       COALESCE(p.avg_post_length, 0)            AS avg_post_length,
       COALESCE(pt.distinct_post_tag_count, 0)   AS distinct_post_tag_count,
       COALESCE(t.distinct_forum_tag_count, 0)   AS distinct_forum_tag_count,
       COALESCE(c.comment_count, 0)              AS comment_count,
       COALESCE(pl.post_like_count, 0)           AS post_like_count,
       COALESCE(cl.comment_like_count, 0)        AS comment_like_count
FROM forum f
LEFT JOIN forum_members m          ON f.id = m.forum_id
LEFT JOIN forum_posts p            ON f.id = p.forum_id
LEFT JOIN forum_post_tags pt       ON f.id = pt.forum_id
LEFT JOIN forum_tags t             ON f.id = t.forum_id
LEFT JOIN forum_comments c         ON f.id = c.forum_id
LEFT JOIN forum_post_likes pl      ON f.id = pl.forum_id
LEFT JOIN forum_comment_likes cl   ON f.id = cl.forum_id
ORDER BY f.id
