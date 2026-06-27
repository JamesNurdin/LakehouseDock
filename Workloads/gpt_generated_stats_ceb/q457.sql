WITH user_posts AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS post_count,
           SUM(score) AS total_post_score,
           AVG(score) AS avg_post_score,
           SUM(viewcount) AS total_views
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid,
           COUNT(*) AS comment_count,
           SUM(score) AS total_comment_score,
           AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT userid,
           COUNT(*) AS vote_cast_count,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cast_count,
           SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cast_count
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_edits AS (
    SELECT lasteditoruserid AS userid,
           COUNT(*) AS edit_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
),
user_posthistory AS (
    SELECT userid,
           COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
)
SELECT u.id AS user_id,
       u.reputation,
       u.creationdate,
       COALESCE(p.post_count, 0)          AS post_count,
       COALESCE(p.total_post_score, 0)    AS total_post_score,
       COALESCE(p.avg_post_score, 0)      AS avg_post_score,
       COALESCE(p.total_views, 0)         AS total_views,
       COALESCE(c.comment_count, 0)       AS comment_count,
       COALESCE(c.total_comment_score, 0) AS total_comment_score,
       COALESCE(c.avg_comment_score, 0)   AS avg_comment_score,
       COALESCE(v.vote_cast_count, 0)     AS vote_cast_count,
       COALESCE(v.upvote_cast_count, 0)   AS upvote_cast_count,
       COALESCE(v.downvote_cast_count, 0) AS downvote_cast_count,
       COALESCE(b.badge_count, 0)         AS badge_count,
       COALESCE(e.edit_count, 0)          AS edit_count,
       COALESCE(ph.posthistory_count, 0)  AS posthistory_count
FROM users u
LEFT JOIN user_posts p        ON p.userid = u.id          -- posts.owneruserid = users.id
LEFT JOIN user_comments c     ON c.userid = u.id          -- comments.userid = users.id
LEFT JOIN user_votes v        ON v.userid = u.id          -- votes.userid = users.id
LEFT JOIN user_badges b       ON b.userid = u.id          -- badges.userid = users.id
LEFT JOIN user_edits e        ON e.userid = u.id          -- posts.lasteditoruserid = users.id
LEFT JOIN user_posthistory ph ON ph.userid = u.id         -- posthistory.userid = users.id
ORDER BY u.reputation DESC
LIMIT 100
