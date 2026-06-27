WITH
  post_owner_metrics AS (
    SELECT
      posts.owneruserid AS user_id,
      COUNT(posts.id) AS post_count,
      SUM(posts.score) AS total_post_score,
      SUM(posts.viewcount) AS total_viewcount,
      AVG(posts.answercount) AS avg_answer_count,
      AVG(posts.commentcount) AS avg_comment_count,
      SUM(posts.favoritecount) AS total_favoritecount
    FROM posts
    GROUP BY posts.owneruserid
  ),
  comment_metrics AS (
    SELECT
      comments.userid AS user_id,
      COUNT(comments.id) AS comment_count,
      SUM(comments.score) AS total_comment_score,
      AVG(comments.score) AS avg_comment_score
    FROM comments
    GROUP BY comments.userid
  ),
  vote_metrics AS (
    SELECT
      votes.userid AS user_id,
      COUNT(votes.id) AS vote_count,
      SUM(CASE WHEN votes.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_given,
      SUM(CASE WHEN votes.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_given,
      SUM(votes.bountyamount) AS total_bounty_given
    FROM votes
    GROUP BY votes.userid
  ),
  badge_metrics AS (
    SELECT
      badges.userid AS user_id,
      COUNT(badges.id) AS badge_count
    FROM badges
    GROUP BY badges.userid
  ),
  post_edit_metrics AS (
    SELECT
      posts.lasteditoruserid AS user_id,
      COUNT(posts.id) AS edited_post_count
    FROM posts
    WHERE posts.lasteditoruserid IS NOT NULL
    GROUP BY posts.lasteditoruserid
  ),
  posthistory_metrics AS (
    SELECT
      posthistory.userid AS user_id,
      COUNT(posthistory.id) AS posthistory_count
    FROM posthistory
    GROUP BY posthistory.userid
  ),
  tag_metrics AS (
    SELECT
      posts.owneruserid AS user_id,
      COUNT(tags.id) AS tag_count
    FROM tags
    JOIN posts ON tags.excerptpostid = posts.id
    GROUP BY posts.owneruserid
  ),
  postlink_metrics AS (
    SELECT
      posts.owneruserid AS user_id,
      COUNT(postlinks.id) AS postlink_count
    FROM postlinks
    JOIN posts ON postlinks.postid = posts.id
    GROUP BY posts.owneruserid
  )
SELECT
  users.id AS user_id,
  users.reputation,
  users.creationdate,
  users.views,
  users.upvotes,
  users.downvotes,
  COALESCE(post_owner_metrics.post_count, 0) AS post_count,
  COALESCE(post_owner_metrics.total_post_score, 0) AS total_post_score,
  COALESCE(post_owner_metrics.total_viewcount, 0) AS total_viewcount,
  COALESCE(post_owner_metrics.avg_answer_count, 0) AS avg_answer_count,
  COALESCE(post_owner_metrics.avg_comment_count, 0) AS avg_comment_count,
  COALESCE(post_owner_metrics.total_favoritecount, 0) AS total_favoritecount,
  COALESCE(comment_metrics.comment_count, 0) AS comment_count,
  COALESCE(comment_metrics.total_comment_score, 0) AS total_comment_score,
  COALESCE(comment_metrics.avg_comment_score, 0) AS avg_comment_score,
  COALESCE(vote_metrics.vote_count, 0) AS vote_count,
  COALESCE(vote_metrics.upvote_given, 0) AS upvote_given,
  COALESCE(vote_metrics.downvote_given, 0) AS downvote_given,
  COALESCE(vote_metrics.total_bounty_given, 0) AS total_bounty_given,
  COALESCE(badge_metrics.badge_count, 0) AS badge_count,
  COALESCE(post_edit_metrics.edited_post_count, 0) AS edited_post_count,
  COALESCE(posthistory_metrics.posthistory_count, 0) AS posthistory_count,
  COALESCE(tag_metrics.tag_count, 0) AS tag_count,
  COALESCE(postlink_metrics.postlink_count, 0) AS postlink_count
FROM users
LEFT JOIN post_owner_metrics ON post_owner_metrics.user_id = users.id
LEFT JOIN comment_metrics ON comment_metrics.user_id = users.id
LEFT JOIN vote_metrics ON vote_metrics.user_id = users.id
LEFT JOIN badge_metrics ON badge_metrics.user_id = users.id
LEFT JOIN post_edit_metrics ON post_edit_metrics.user_id = users.id
LEFT JOIN posthistory_metrics ON posthistory_metrics.user_id = users.id
LEFT JOIN tag_metrics ON tag_metrics.user_id = users.id
LEFT JOIN postlink_metrics ON postlink_metrics.user_id = users.id
ORDER BY users.reputation DESC
LIMIT 100
