WITH forum_posts AS (
    SELECT f.id AS forum_id,
           COUNT(p.id) AS post_count,
           AVG(p.length) AS avg_post_length
    FROM forum f
    JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id
),
forum_post_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(plp.person_id) AS post_like_count
    FROM post p
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY p.container_forum_id
),
forum_comments AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(c.id) AS comment_count,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_comment_likes AS (
    SELECT p.container_forum_id AS forum_id,
           COUNT(plc.person_id) AS comment_like_count
    FROM comment c
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_participants AS (
    SELECT forum_id,
           COUNT(DISTINCT person_id) AS participant_count
    FROM (
        SELECT p.container_forum_id AS forum_id, p.creator_person_id AS person_id
        FROM post p
        UNION ALL
        SELECT p.container_forum_id AS forum_id, c.creator_person_id AS person_id
        FROM comment c
        JOIN post p ON c.parent_post_id = p.id
    ) AS u
    GROUP BY forum_id
)
SELECT f.id AS forum_id,
       f.title AS forum_title,
       m.first_name AS moderator_first_name,
       m.last_name AS moderator_last_name,
       COALESCE(fp.post_count, 0) AS post_count,
       COALESCE(fp.avg_post_length, 0) AS avg_post_length,
       COALESCE(fc.comment_count, 0) AS comment_count,
       COALESCE(fc.avg_comment_length, 0) AS avg_comment_length,
       COALESCE(fpl.post_like_count, 0) AS post_like_count,
       COALESCE(fcl.comment_like_count, 0) AS comment_like_count,
       COALESCE(fp_part.participant_count, 0) AS participant_count
FROM forum f
LEFT JOIN forum_posts fp ON fp.forum_id = f.id
LEFT JOIN forum_post_likes fpl ON fpl.forum_id = f.id
LEFT JOIN forum_comments fc ON fc.forum_id = f.id
LEFT JOIN forum_comment_likes fcl ON fcl.forum_id = f.id
LEFT JOIN forum_participants fp_part ON fp_part.forum_id = f.id
LEFT JOIN person m ON f.moderator_person_id = m.id
ORDER BY f.id
