WITH
    forum_posts AS (
        SELECT container_forum_id AS forum_id,
               COUNT(*) AS post_count
        FROM post
        GROUP BY container_forum_id
    ),
    forum_comments AS (
        SELECT po.container_forum_id AS forum_id,
               COUNT(*) AS comment_count
        FROM comment c
        JOIN post po ON c.parent_post_id = po.id
        GROUP BY po.container_forum_id
    ),
    forum_post_likes AS (
        SELECT po.container_forum_id AS forum_id,
               COUNT(*) AS post_like_count
        FROM person_likes_post plp
        JOIN post po ON plp.post_id = po.id
        GROUP BY po.container_forum_id
    ),
    forum_comment_likes AS (
        SELECT po.container_forum_id AS forum_id,
               COUNT(*) AS comment_like_count
        FROM person_likes_comment plc
        JOIN comment c ON plc.comment_id = c.id
        JOIN post po ON c.parent_post_id = po.id
        GROUP BY po.container_forum_id
    ),
    forum_members AS (
        SELECT forum_id,
               COUNT(*) AS member_count
        FROM forum_has_member_person
        GROUP BY forum_id
    ),
    forum_avg_post_length AS (
        SELECT container_forum_id AS forum_id,
               AVG(length) AS avg_post_length
        FROM post
        GROUP BY container_forum_id
    ),
    forum_avg_comment_length AS (
        SELECT po.container_forum_id AS forum_id,
               AVG(c.length) AS avg_comment_length
        FROM comment c
        JOIN post po ON c.parent_post_id = po.id
        GROUP BY po.container_forum_id
    )
SELECT f.id AS forum_id,
       f.title AS forum_title,
       p_mod.first_name AS moderator_first_name,
       p_mod.last_name AS moderator_last_name,
       COALESCE(fp.post_count, 0) AS total_posts,
       COALESCE(fc.comment_count, 0) AS total_comments,
       COALESCE(fpl.post_like_count, 0) AS total_post_likes,
       COALESCE(fcl.comment_like_count, 0) AS total_comment_likes,
       COALESCE(fm.member_count, 0) AS total_members,
       COALESCE(fap.avg_post_length, 0) AS avg_post_length,
       COALESCE(fac.avg_comment_length, 0) AS avg_comment_length,
       (COALESCE(fp.post_count, 0) + COALESCE(fc.comment_count, 0) + COALESCE(fpl.post_like_count, 0) + COALESCE(fcl.comment_like_count, 0)) AS total_engagement
FROM forum f
JOIN person p_mod ON f.moderator_person_id = p_mod.id
LEFT JOIN forum_posts fp ON f.id = fp.forum_id
LEFT JOIN forum_comments fc ON f.id = fc.forum_id
LEFT JOIN forum_post_likes fpl ON f.id = fpl.forum_id
LEFT JOIN forum_comment_likes fcl ON f.id = fcl.forum_id
LEFT JOIN forum_members fm ON f.id = fm.forum_id
LEFT JOIN forum_avg_post_length fap ON f.id = fap.forum_id
LEFT JOIN forum_avg_comment_length fac ON f.id = fac.forum_id
ORDER BY total_engagement DESC
LIMIT 5
