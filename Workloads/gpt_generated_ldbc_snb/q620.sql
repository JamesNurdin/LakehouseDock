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
forum_comments AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_post_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS post_like_count
    FROM person_likes_post pl
    JOIN post p ON pl.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_comment_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(*) AS comment_like_count
    FROM person_likes_comment cl
    JOIN comment c ON cl.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT f.id,
       f.title,
       COALESCE(fm.member_count, 0)          AS member_count,
       COALESCE(fp.post_count, 0)            AS post_count,
       COALESCE(fp.avg_post_length, 0)       AS avg_post_length,
       COALESCE(fc.comment_count, 0)         AS comment_count,
       COALESCE(fc.avg_comment_length, 0)    AS avg_comment_length,
       COALESCE(fpl.post_like_count, 0)      AS post_like_count,
       COALESCE(fcl.comment_like_count, 0)   AS comment_like_count,
       (COALESCE(fpl.post_like_count, 0) + COALESCE(fcl.comment_like_count, 0)) AS total_like_count
FROM forum f
LEFT JOIN forum_members fm          ON fm.forum_id = f.id
LEFT JOIN forum_posts fp            ON fp.forum_id = f.id
LEFT JOIN forum_comments fc        ON fc.forum_id = f.id
LEFT JOIN forum_post_likes fpl      ON fpl.forum_id = f.id
LEFT JOIN forum_comment_likes fcl   ON fcl.forum_id = f.id
ORDER BY total_like_count DESC, f.id
LIMIT 10
