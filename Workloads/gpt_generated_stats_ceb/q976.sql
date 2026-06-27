WITH
    user_posts AS (
        SELECT owneruserid AS userid,
               COUNT(*) AS post_count,
               COALESCE(SUM(score), 0) AS total_post_score,
               COALESCE(SUM(viewcount), 0) AS total_views
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT userid,
               COUNT(*) AS comment_count,
               COALESCE(SUM(score), 0) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    user_hist_edits AS (
        SELECT userid,
               COUNT(*) AS edit_hist_count
        FROM posthistory
        GROUP BY userid
    ),
    user_last_edits AS (
        SELECT lasteditoruserid AS userid,
               COUNT(*) AS edit_last_count
        FROM posts
        WHERE lasteditoruserid IS NOT NULL
        GROUP BY lasteditoruserid
    ),
    user_link_counts AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS link_count
        FROM posts p
        JOIN postlinks pl ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.total_views, 0) AS total_views,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(uh.edit_hist_count, 0) AS edit_hist_count,
       COALESCE(ul.edit_last_count, 0) AS edit_last_count,
       COALESCE(ulc.link_count, 0) AS link_count,
       (COALESCE(up.post_count, 0) + COALESCE(uc.comment_count, 0) + COALESCE(uh.edit_hist_count, 0) + COALESCE(ul.edit_last_count, 0) + COALESCE(ulc.link_count, 0)) AS total_activity,
       CASE WHEN COALESCE(up.post_count, 0) > 0 THEN COALESCE(up.total_post_score, 0) / CAST(up.post_count AS double) ELSE NULL END AS avg_post_score,
       CASE WHEN COALESCE(uc.comment_count, 0) > 0 THEN COALESCE(uc.total_comment_score, 0) / CAST(uc.comment_count AS double) ELSE NULL END AS avg_comment_score
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_hist_edits uh ON uh.userid = u.id
LEFT JOIN user_last_edits ul ON ul.userid = u.id
LEFT JOIN user_link_counts ulc ON ulc.userid = u.id
ORDER BY total_activity DESC
LIMIT 100
