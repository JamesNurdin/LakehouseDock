WITH forum_posts AS (
    SELECT f.id AS forum_id,
           f.title AS forum_title,
           COUNT(DISTINCT p.id) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM forum f
    JOIN post p
      ON p.container_forum_id = f.id
    GROUP BY f.id, f.title
),
forum_comments AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM forum f
    JOIN post p
      ON p.container_forum_id = f.id
    JOIN comment c
      ON c.parent_post_id = p.id
    GROUP BY f.id
),
forum_members AS (
    SELECT f.id AS forum_id,
           COUNT(DISTINCT fm.person_id) AS member_count
    FROM forum f
    JOIN forum_has_member_person fm
      ON fm.forum_id = f.id
    GROUP BY f.id
),
forum_post_likes AS (
    SELECT f.id AS forum_id,
           COUNT(pl.person_id) AS post_like_count
    FROM forum f
    JOIN post p
      ON p.container_forum_id = f.id
    JOIN person_likes_post pl
      ON pl.post_id = p.id
    GROUP BY f.id
),
forum_comment_likes AS (
    SELECT f.id AS forum_id,
           COUNT(cl.person_id) AS comment_like_count
    FROM forum f
    JOIN post p
      ON p.container_forum_id = f.id
    JOIN comment c
      ON c.parent_post_id = p.id
    JOIN person_likes_comment cl
      ON cl.comment_id = c.id
    GROUP BY f.id
),
forum_moderators AS (
    SELECT f.id AS forum_id,
           p.first_name AS moderator_first_name,
           p.last_name AS moderator_last_name
    FROM forum f
    JOIN person p
      ON f.moderator_person_id = p.id
)
SELECT
    fp.forum_id,
    fp.forum_title,
    fm.moderator_first_name,
    fm.moderator_last_name,
    fp.post_count,
    fc.comment_count,
    fmem.member_count,
    fp.avg_post_length,
    fc.avg_comment_length,
    CASE WHEN fp.post_count = 0 THEN 0 ELSE CAST(fpl.post_like_count AS double) / fp.post_count END AS avg_likes_per_post,
    CASE WHEN fc.comment_count = 0 THEN 0 ELSE CAST(fcl.comment_like_count AS double) / fc.comment_count END AS avg_likes_per_comment
FROM forum_posts fp
LEFT JOIN forum_comments fc ON fc.forum_id = fp.forum_id
LEFT JOIN forum_members fmem ON fmem.forum_id = fp.forum_id
LEFT JOIN forum_post_likes fpl ON fpl.forum_id = fp.forum_id
LEFT JOIN forum_comment_likes fcl ON fcl.forum_id = fp.forum_id
LEFT JOIN forum_moderators fm ON fm.forum_id = fp.forum_id
ORDER BY fp.post_count DESC
LIMIT 10
