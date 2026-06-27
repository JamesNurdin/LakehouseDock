WITH user_posts AS (
   SELECT owneruserid AS userid,
          COUNT(*) AS post_count,
          COALESCE(SUM(score), 0) AS total_post_score,
          COALESCE(AVG(score), 0) AS avg_post_score
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
          COUNT(*) AS vote_count,
          COALESCE(SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_given,
          COALESCE(SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_given
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
   SELECT userid,
          COUNT(*) AS edit_count
   FROM posthistory
   GROUP BY userid
),
user_linked_posts AS (
   SELECT p.owneruserid AS userid,
          COUNT(pl.id) AS linked_post_count
   FROM posts p
   JOIN postlinks pl ON pl.postid = p.id
   GROUP BY p.owneruserid
)
SELECT u.id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.avg_post_score, 0) AS avg_post_score,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uv.vote_count, 0) AS vote_count,
       COALESCE(uv.upvote_given, 0) AS upvote_given,
       COALESCE(uv.downvote_given, 0) AS downvote_given,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(ue.edit_count, 0) AS edit_count,
       COALESCE(ul.linked_post_count, 0) AS linked_post_count
FROM users u
LEFT JOIN user_posts up          ON u.id = up.userid
LEFT JOIN user_comments uc      ON u.id = uc.userid
LEFT JOIN user_votes uv         ON u.id = uv.userid
LEFT JOIN user_badges ub        ON u.id = ub.userid
LEFT JOIN user_edits ue         ON u.id = ue.userid
LEFT JOIN user_linked_posts ul  ON u.id = ul.userid
ORDER BY total_post_score DESC
LIMIT 10
