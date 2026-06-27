WITH
    user_posts AS (
        SELECT owneruserid,
               COUNT(*) AS post_count,
               SUM(score) AS total_score,
               AVG(score) AS avg_score,
               SUM(viewcount) AS total_views,
               SUM(answercount) AS total_answers,
               SUM(commentcount) AS total_comments_on_posts,
               SUM(favoritecount) AS total_favorites
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT userid,
               COUNT(*) AS comment_count
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT userid,
               COUNT(*) AS votes_cast,
               SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_cast,
               SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_cast
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT p.owneruserid,
               COUNT(*) AS votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_edits AS (
        SELECT lasteditoruserid,
               COUNT(*) AS edit_count
        FROM posts
        WHERE lasteditoruserid IS NOT NULL
        GROUP BY lasteditoruserid
    )
SELECT u.id,
       u.reputation,
       COALESCE(up.post_count, 0)               AS post_count,
       COALESCE(up.total_score, 0)               AS total_score,
       COALESCE(up.avg_score, 0)                 AS avg_score,
       COALESCE(up.total_views, 0)               AS total_views,
       COALESCE(up.total_answers, 0)             AS total_answers,
       COALESCE(up.total_comments_on_posts, 0)  AS total_comments_on_posts,
       COALESCE(up.total_favorites, 0)           AS total_favorites,
       COALESCE(uc.comment_count, 0)             AS comment_count,
       COALESCE(uvc.votes_cast, 0)               AS votes_cast,
       COALESCE(uvc.upvotes_cast, 0)             AS upvotes_cast,
       COALESCE(uvc.downvotes_cast, 0)           AS downvotes_cast,
       COALESCE(uvr.votes_received, 0)           AS votes_received,
       COALESCE(ue.edit_count, 0)                AS edit_count
FROM users u
LEFT JOIN user_posts up           ON u.id = up.owneruserid
LEFT JOIN user_comments uc        ON u.id = uc.userid
LEFT JOIN user_votes_cast uvc     ON u.id = uvc.userid
LEFT JOIN user_votes_received uvr ON u.id = uvr.owneruserid
LEFT JOIN user_edits ue           ON u.id = ue.lasteditoruserid
ORDER BY u.reputation DESC
LIMIT 100
