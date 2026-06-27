WITH
  user_posts AS (
    SELECT
      p.owneruserid AS userid,
      COUNT(*) AS post_count,
      SUM(p.score) AS post_score_sum,
      AVG(p.score) AS post_score_avg,
      SUM(p.answercount) AS total_answers,
      SUM(p.commentcount) AS total_comments_on_posts
    FROM posts p
    GROUP BY p.owneruserid
  ),
  user_edits AS (
    SELECT
      p.lasteditoruserid AS userid,
      COUNT(*) AS edit_count
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
  ),
  user_comments AS (
    SELECT
      c.userid,
      COUNT(*) AS comment_count,
      SUM(c.score) AS comment_score_sum,
      AVG(c.score) AS comment_score_avg
    FROM comments c
    GROUP BY c.userid
  ),
  user_votes_cast AS (
    SELECT
      v.userid,
      COUNT(*) AS votes_cast,
      SUM(v.bountyamount) AS bounty_sum
    FROM votes v
    GROUP BY v.userid
  ),
  user_votes_received AS (
    SELECT
      p.owneruserid AS userid,
      COUNT(*) AS votes_received,
      SUM(v.bountyamount) AS bounty_received_sum
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
  ),
  user_badges AS (
    SELECT
      b.userid,
      COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
  )
SELECT
  u.id AS user_id,
  u.reputation,
  ROW_NUMBER() OVER (ORDER BY u.reputation DESC) AS reputation_rank,
  u.creationdate,
  u.views,
  u.upvotes,
  u.downvotes,
  COALESCE(up.post_count, 0) AS post_count,
  COALESCE(up.post_score_sum, 0) AS post_score_sum,
  COALESCE(up.post_score_avg, 0) AS post_score_avg,
  COALESCE(up.total_answers, 0) AS total_answers,
  COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
  COALESCE(ue.edit_count, 0) AS edit_count,
  COALESCE(uc.comment_count, 0) AS comment_count,
  COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
  COALESCE(uc.comment_score_avg, 0) AS comment_score_avg,
  COALESCE(uvc.votes_cast, 0) AS votes_cast,
  COALESCE(uvc.bounty_sum, 0) AS bounty_sum,
  COALESCE(uvr.votes_received, 0) AS votes_received,
  COALESCE(uvr.bounty_received_sum, 0) AS bounty_received_sum,
  COALESCE(ub.badge_count, 0) AS badge_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
