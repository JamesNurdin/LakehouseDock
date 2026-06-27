WITH user_posts AS (
   SELECT u.id AS user_id,
          u.reputation,
          COUNT(p.id) AS post_count,
          COALESCE(SUM(p.score), 0) AS post_score_sum,
          COALESCE(SUM(p.viewcount), 0) AS post_viewcount_sum,
          COALESCE(SUM(p.answercount), 0) AS post_answercount_sum,
          COALESCE(SUM(p.commentcount), 0) AS post_commentcount_sum,
          COALESCE(SUM(p.favoritecount), 0) AS post_favoritecount_sum
   FROM users u
   LEFT JOIN posts p ON p.owneruserid = u.id
   GROUP BY u.id, u.reputation
),
user_comments AS (
   SELECT u.id AS user_id,
          COUNT(c.id) AS comment_count,
          COALESCE(SUM(c.score), 0) AS comment_score_sum
   FROM users u
   LEFT JOIN comments c ON c.userid = u.id
   GROUP BY u.id
),
user_votes_cast AS (
   SELECT u.id AS user_id,
          COUNT(v.id) AS votes_cast_count,
          COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_cast_count,
          COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_cast_count,
          COALESCE(SUM(v.bountyamount), 0) AS bounty_amount_sum
   FROM users u
   LEFT JOIN votes v ON v.userid = u.id
   GROUP BY u.id
),
user_votes_received AS (
   SELECT u.id AS user_id,
          COUNT(v.id) AS votes_received_count,
          COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_received_count,
          COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_received_count,
          COALESCE(SUM(v.bountyamount), 0) AS bounty_received_sum
   FROM users u
   LEFT JOIN posts p ON p.owneruserid = u.id
   LEFT JOIN votes v ON v.postid = p.id
   GROUP BY u.id
),
user_badges AS (
   SELECT u.id AS user_id,
          COUNT(b.id) AS badge_count
   FROM users u
   LEFT JOIN badges b ON b.userid = u.id
   GROUP BY u.id
),
user_edits AS (
   SELECT u.id AS user_id,
          COUNT(p.id) AS edited_posts_count
   FROM users u
   LEFT JOIN posts p ON p.lasteditoruserid = u.id
   GROUP BY u.id
),
user_tags AS (
   SELECT u.id AS user_id,
          COUNT(t.id) AS tag_count
   FROM users u
   LEFT JOIN posts p ON p.owneruserid = u.id
   LEFT JOIN tags t ON t.excerptpostid = p.id
   GROUP BY u.id
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0) AS total_posts_owned,
       COALESCE(up.post_score_sum, 0) AS total_posts_score,
       COALESCE(up.post_viewcount_sum, 0) AS total_posts_views,
       COALESCE(up.post_answercount_sum, 0) AS total_answers_given,
       COALESCE(up.post_commentcount_sum, 0) AS total_post_comments,
       COALESCE(up.post_favoritecount_sum, 0) AS total_favorites,
       COALESCE(uc.comment_count, 0) AS total_comments_made,
       COALESCE(uc.comment_score_sum, 0) AS total_comment_score,
       COALESCE(uvc.votes_cast_count, 0) AS total_votes_cast,
       COALESCE(uvc.upvote_cast_count, 0) AS total_upvotes_cast,
       COALESCE(uvc.downvote_cast_count, 0) AS total_downvotes_cast,
       COALESCE(uvc.bounty_amount_sum, 0) AS total_bounty_amount_cast,
       COALESCE(uvr.votes_received_count, 0) AS total_votes_received,
       COALESCE(uvr.upvote_received_count, 0) AS total_upvotes_received,
       COALESCE(uvr.downvote_received_count, 0) AS total_downvotes_received,
       COALESCE(uvr.bounty_received_sum, 0) AS total_bounty_amount_received,
       COALESCE(ub.badge_count, 0) AS total_badges_earned,
       COALESCE(ue.edited_posts_count, 0) AS total_posts_edited,
       COALESCE(ut.tag_count, 0) AS total_tags_on_owned_posts
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
