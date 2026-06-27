WITH user_posts AS (
        SELECT owneruserid,
               COUNT(*) AS post_count,
               AVG(score) AS avg_post_score
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT userid,
               COUNT(*) AS comment_count
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT userid,
               COUNT(*) AS vote_count
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT userid,
               COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_postlinks AS (
        SELECT p.owneruserid,
               COUNT(pl.id) AS postlink_count
        FROM posts p
        LEFT JOIN postlinks pl ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT u.id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       up.avg_post_score,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uv.vote_count, 0) AS vote_count,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(upk.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes uv ON uv.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_postlinks upk ON upk.owneruserid = u.id
ORDER BY u.reputation DESC
LIMIT 10
