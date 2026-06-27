WITH
  user_badge_counts AS (
    SELECT
      userid,
      COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
  ),
  user_post_stats AS (
    SELECT
      owneruserid AS userid,
      COUNT(*) AS post_count,
      SUM(score) AS total_post_score,
      AVG(score) AS avg_post_score,
      SUM(answercount) AS total_answer_count,
      SUM(commentcount) AS total_comment_count,
      SUM(viewcount) AS total_view_count,
      SUM(favoritecount) AS total_favorite_count
    FROM posts
    GROUP BY owneruserid
  ),
  user_comment_stats AS (
    SELECT
      userid,
      COUNT(*) AS comment_count,
      SUM(score) AS total_comment_score,
      AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY userid
  ),
  user_vote_stats AS (
    SELECT
      userid,
      COUNT(*) AS vote_count,
      SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
      SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
      SUM(bountyamount) AS total_bounty_amount
    FROM votes
    GROUP BY userid
  ),
  user_edit_stats AS (
    SELECT
      lasteditoruserid AS userid,
      COUNT(*) AS edit_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
  )
SELECT
  u.id,
  u.reputation,
  COALESCE(bc.badge_count, 0) AS badge_count,
  COALESCE(pc.post_count, 0) AS post_count,
  COALESCE(pc.total_post_score, 0) AS total_post_score,
  COALESCE(pc.avg_post_score, 0) AS avg_post_score,
  COALESCE(pc.total_answer_count, 0) AS total_answer_count,
  COALESCE(pc.total_comment_count, 0) AS total_post_comment_count,
  COALESCE(pc.total_view_count, 0) AS total_view_count,
  COALESCE(pc.total_favorite_count, 0) AS total_favorite_count,
  COALESCE(cc.comment_count, 0) AS comment_count,
  COALESCE(cc.total_comment_score, 0) AS total_comment_score,
  COALESCE(cc.avg_comment_score, 0) AS avg_comment_score,
  COALESCE(vc.vote_count, 0) AS vote_count,
  COALESCE(vc.upvote_count, 0) AS upvote_count,
  COALESCE(vc.downvote_count, 0) AS downvote_count,
  COALESCE(vc.total_bounty_amount, 0) AS total_bounty_amount,
  COALESCE(ec.edit_count, 0) AS edit_count
FROM users u
LEFT JOIN user_badge_counts bc ON bc.userid = u.id
LEFT JOIN user_post_stats pc ON pc.userid = u.id
LEFT JOIN user_comment_stats cc ON cc.userid = u.id
LEFT JOIN user_vote_stats vc ON vc.userid = u.id
LEFT JOIN user_edit_stats ec ON ec.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
