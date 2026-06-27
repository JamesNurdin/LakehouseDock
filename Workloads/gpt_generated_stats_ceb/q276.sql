WITH
user_posts AS (
   SELECT owneruserid AS user_id,
          COUNT(*) AS post_count,
          SUM(score) AS total_post_score,
          AVG(score) AS avg_post_score,
          SUM(viewcount) AS total_viewcount,
          SUM(answercount) AS total_answercount,
          SUM(commentcount) AS total_commentcount,
          SUM(favoritecount) AS total_favoritecount
   FROM posts
   GROUP BY owneruserid
),
user_comments AS (
   SELECT userid AS user_id,
          COUNT(*) AS comment_count,
          SUM(score) AS total_comment_score,
          AVG(score) AS avg_comment_score
   FROM comments
   GROUP BY userid
),
user_badges AS (
   SELECT userid AS user_id,
          COUNT(*) AS badge_count,
          MIN(date) AS first_badge_date,
          MAX(date) AS last_badge_date
   FROM badges
   GROUP BY userid
),
user_edits AS (
   SELECT lasteditoruserid AS user_id,
          COUNT(*) AS edited_post_count,
          SUM(score) AS total_edit_score
   FROM posts
   WHERE lasteditoruserid IS NOT NULL
   GROUP BY lasteditoruserid
)
SELECT u.id,
       u.reputation,
       u.creationdate AS user_creationdate,
       u.views,
       u.upvotes,
       u.downvotes,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(p.total_post_score, 0) AS total_post_score,
       COALESCE(p.avg_post_score, 0) AS avg_post_score,
       COALESCE(p.total_viewcount, 0) AS total_viewcount,
       COALESCE(p.total_answercount, 0) AS total_answercount,
       COALESCE(p.total_commentcount, 0) AS total_commentcount,
       COALESCE(p.total_favoritecount, 0) AS total_favoritecount,
       COALESCE(c.comment_count, 0) AS comment_count,
       COALESCE(c.total_comment_score, 0) AS total_comment_score,
       COALESCE(c.avg_comment_score, 0) AS avg_comment_score,
       COALESCE(b.badge_count, 0) AS badge_count,
       b.first_badge_date,
       b.last_badge_date,
       COALESCE(e.edited_post_count, 0) AS edited_post_count,
       COALESCE(e.total_edit_score, 0) AS total_edit_score,
       (u.reputation
        + COALESCE(p.total_post_score, 0)
        + COALESCE(c.total_comment_score, 0)
        + COALESCE(b.badge_count, 0) * 10
        + COALESCE(e.edited_post_count, 0) * 5) AS user_engagement_score,
       RANK() OVER (ORDER BY (u.reputation
        + COALESCE(p.total_post_score, 0)
        + COALESCE(c.total_comment_score, 0)
        + COALESCE(b.badge_count, 0) * 10
        + COALESCE(e.edited_post_count, 0) * 5) DESC) AS engagement_rank
FROM users u
LEFT JOIN user_posts p ON p.user_id = u.id
LEFT JOIN user_comments c ON c.user_id = u.id
LEFT JOIN user_badges b ON b.user_id = u.id
LEFT JOIN user_edits e ON e.user_id = u.id
ORDER BY user_engagement_score DESC
LIMIT 100
