WITH user_posts AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS post_count,
               SUM(p.score) AS total_post_score,
               SUM(p.viewcount) AS total_viewcount
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_comments AS (
        SELECT c.userid,
               COUNT(*) AS comment_count
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes AS (
        SELECT v.userid,
               COUNT(*) AS votes_cast
        FROM votes v
        GROUP BY v.userid
    ),
    user_badges AS (
        SELECT b.userid,
               COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_edits AS (
        SELECT ph.userid,
               COUNT(*) AS edit_count
        FROM posthistory ph
        GROUP BY ph.userid
    )
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0)          AS post_count,
       COALESCE(up.total_post_score, 0)    AS total_post_score,
       COALESCE(up.total_viewcount, 0)    AS total_viewcount,
       COALESCE(uc.comment_count, 0)      AS comment_count,
       COALESCE(uv.votes_cast, 0)         AS votes_cast,
       COALESCE(ub.badge_count, 0)        AS badge_count,
       COALESCE(uh.edit_count, 0)         AS edit_count,
       COALESCE(up.post_count, 0) + COALESCE(uc.comment_count, 0) + COALESCE(uv.votes_cast, 0) + COALESCE(ub.badge_count, 0) + COALESCE(uh.edit_count, 0) AS activity_score,
       CASE WHEN COALESCE(up.post_count, 0) > 0
            THEN COALESCE(up.total_post_score, 0) / NULLIF(COALESCE(up.post_count, 0), 0)
            ELSE 0
       END AS avg_post_score
FROM users u
LEFT JOIN user_posts   up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes   uv ON uv.userid = u.id
LEFT JOIN user_badges  ub ON ub.userid = u.id
LEFT JOIN user_edits   uh ON uh.userid = u.id
ORDER BY activity_score DESC
LIMIT 10
