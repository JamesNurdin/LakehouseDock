WITH user_posts AS (
   SELECT p.owneruserid AS userid,
          COUNT(*) AS post_count,
          SUM(p.score) AS total_post_score,
          SUM(p.viewcount) AS total_viewcount,
          SUM(p.answercount) AS total_answercount,
          SUM(p.commentcount) AS total_commentcount,
          SUM(p.favoritecount) AS total_favoritecount
   FROM posts p
   GROUP BY p.owneruserid
),
user_votes_received AS (
   SELECT p.owneruserid AS userid,
          COUNT(v.id) AS votes_received,
          SUM(CASE WHEN v.bountyamount IS NOT NULL THEN v.bountyamount ELSE 0 END) AS total_bounty_received,
          AVG(v.bountyamount) AS avg_bounty_received
   FROM posts p
   LEFT JOIN votes v ON v.postid = p.id
   GROUP BY p.owneruserid
),
user_votes_cast AS (
   SELECT v.userid AS userid,
          COUNT(*) AS votes_cast
   FROM votes v
   GROUP BY v.userid
),
user_comments_made AS (
   SELECT c.userid AS userid,
          COUNT(*) AS comment_count,
          SUM(c.score) AS total_comment_score
   FROM comments c
   GROUP BY c.userid
),
user_badges AS (
   SELECT b.userid AS userid,
          COUNT(*) AS badge_count
   FROM badges b
   GROUP BY b.userid
),
user_posthistory AS (
   SELECT ph.userid AS userid,
          COUNT(*) AS posthistory_count
   FROM posthistory ph
   GROUP BY ph.userid
),
user_tags AS (
   SELECT p.owneruserid AS userid,
          COUNT(DISTINCT t.id) AS distinct_tag_count
   FROM posts p
   JOIN tags t ON t.excerptpostid = p.id
   GROUP BY p.owneruserid
),
user_postlinks AS (
   SELECT p.owneruserid AS userid,
          COUNT(*) AS postlink_count
   FROM posts p
   JOIN postlinks pl ON pl.postid = p.id
   GROUP BY p.owneruserid
),
user_summary AS (
   SELECT u.id AS userid,
          u.reputation,
          u.creationdate,
          u.views,
          u.upvotes,
          u.downvotes,
          COALESCE(up.post_count, 0) AS post_count,
          COALESCE(up.total_post_score, 0) AS total_post_score,
          COALESCE(up.total_viewcount, 0) AS total_viewcount,
          COALESCE(up.total_answercount, 0) AS total_answercount,
          COALESCE(up.total_commentcount, 0) AS total_commentcount,
          COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
          COALESCE(vr.votes_received, 0) AS votes_received,
          COALESCE(vr.total_bounty_received, 0) AS total_bounty_received,
          COALESCE(vr.avg_bounty_received, 0) AS avg_bounty_received,
          COALESCE(vc.votes_cast, 0) AS votes_cast,
          COALESCE(cm.comment_count, 0) AS comment_count,
          COALESCE(cm.total_comment_score, 0) AS total_comment_score,
          COALESCE(b.badge_count, 0) AS badge_count,
          COALESCE(ph.posthistory_count, 0) AS posthistory_count,
          COALESCE(tg.distinct_tag_count, 0) AS distinct_tag_count,
          COALESCE(pl.postlink_count, 0) AS postlink_count
   FROM users u
   LEFT JOIN user_posts up ON up.userid = u.id
   LEFT JOIN user_votes_received vr ON vr.userid = u.id
   LEFT JOIN user_votes_cast vc ON vc.userid = u.id
   LEFT JOIN user_comments_made cm ON cm.userid = u.id
   LEFT JOIN user_badges b ON b.userid = u.id
   LEFT JOIN user_posthistory ph ON ph.userid = u.id
   LEFT JOIN user_tags tg ON tg.userid = u.id
   LEFT JOIN user_postlinks pl ON pl.userid = u.id
)
SELECT
   userid,
   reputation,
   creationdate,
   views,
   upvotes,
   downvotes,
   post_count,
   total_post_score,
   total_viewcount,
   total_answercount,
   total_commentcount,
   total_favoritecount,
   votes_received,
   total_bounty_received,
   avg_bounty_received,
   votes_cast,
   comment_count,
   total_comment_score,
   badge_count,
   posthistory_count,
   distinct_tag_count,
   postlink_count
FROM user_summary
ORDER BY reputation DESC
LIMIT 20
