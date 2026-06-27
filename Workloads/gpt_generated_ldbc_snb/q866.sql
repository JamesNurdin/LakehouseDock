/*
  Analytical query: top 10 forums by total likes on their posts, with additional
  statistics such as post count, comment count, average comment length, and the
  number of distinct participants (posters, likers, commenters).
*/
WITH post_likes AS (
    SELECT p.id AS post_id,
           COUNT(plp.person_id) AS like_count
    FROM post p
    LEFT JOIN person_likes_post plp
           ON plp.post_id = p.id
    GROUP BY p.id
),
post_comments AS (
    SELECT p.id AS post_id,
           COUNT(c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM post p
    LEFT JOIN comment c
           ON c.parent_post_id = p.id
    GROUP BY p.id
),
forum_agg AS (
    SELECT f.id AS forum_id,
           f.title,
           COUNT(p.id) AS post_count,
           SUM(COALESCE(pl.like_count, 0)) AS total_likes,
           SUM(COALESCE(pc.comment_count, 0)) AS total_comments,
           AVG(COALESCE(pc.avg_comment_length, 0)) AS avg_comment_length_per_post
    FROM forum f
    LEFT JOIN post p
           ON p.container_forum_id = f.id
    LEFT JOIN post_likes pl
           ON pl.post_id = p.id
    LEFT JOIN post_comments pc
           ON pc.post_id = p.id
    GROUP BY f.id, f.title
),
forum_participants AS (
    SELECT forum_id,
           COUNT(DISTINCT participant_id) AS participant_count
    FROM (
        SELECT p.container_forum_id AS forum_id,
               p.creator_person_id AS participant_id
        FROM post p
        UNION ALL
        SELECT p.container_forum_id AS forum_id,
               plp.person_id AS participant_id
        FROM post p
        JOIN person_likes_post plp
              ON plp.post_id = p.id
        UNION ALL
        SELECT p.container_forum_id AS forum_id,
               c.creator_person_id AS participant_id
        FROM comment c
        JOIN post p
              ON c.parent_post_id = p.id
    ) participants
    GROUP BY forum_id
)
SELECT fa.forum_id,
       fa.title,
       fa.post_count,
       fa.total_likes,
       fa.total_comments,
       fa.avg_comment_length_per_post,
       COALESCE(fp.participant_count, 0) AS participant_count
FROM forum_agg fa
LEFT JOIN forum_participants fp
       ON fp.forum_id = fa.forum_id
ORDER BY fa.total_likes DESC
LIMIT 10
