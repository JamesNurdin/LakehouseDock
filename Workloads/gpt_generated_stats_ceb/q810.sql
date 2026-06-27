WITH user_posts AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS post_count,
           SUM(score) AS total_post_score,
           AVG(viewcount) AS avg_viewcount
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid,
           COUNT(*) AS comment_count,
           SUM(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT userid,
           COUNT(*) AS vote_count,
           SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT ph.userid,
           COUNT(*) AS posthistory_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY ph.userid
)
SELECT u.id,
       u.reputation,
       u.creationdate,
       u.views,
       u.upvotes,
       u.downvotes,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(p.total_post_score, 0) AS total_post_score,
       COALESCE(p.avg_viewcount, 0) AS avg_viewcount,
       COALESCE(c.comment_count, 0) AS comment_count,
       COALESCE(c.total_comment_score, 0) AS total_comment_score,
       COALESCE(v.vote_count, 0) AS vote_count,
       COALESCE(v.upvote_count, 0) AS upvote_count,
       COALESCE(v.downvote_count, 0) AS downvote_count,
       COALESCE(b.badge_count, 0) AS badge_count,
       COALESCE(ph.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN user_posts p ON u.id = p.userid
LEFT JOIN user_comments c ON u.id = c.userid
LEFT JOIN user_votes v ON u.id = v.userid
LEFT JOIN user_badges b ON u.id = b.userid
LEFT JOIN user_posthistory ph ON u.id = ph.userid
ORDER BY total_post_score DESC
LIMIT 100
