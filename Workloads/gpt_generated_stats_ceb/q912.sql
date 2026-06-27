WITH user_posts AS (
   SELECT u.id AS user_id,
          u.reputation,
          COUNT(p.id) AS post_count,
          COALESCE(SUM(p.score), 0) AS total_post_score,
          COALESCE(SUM(p.viewcount), 0) AS total_viewcount,
          COALESCE(SUM(p.favoritecount), 0) AS total_favoritecount
   FROM users u
   LEFT JOIN posts p ON p.owneruserid = u.id
   GROUP BY u.id, u.reputation
),
user_badges AS (
   SELECT u.id AS user_id,
          COUNT(b.id) AS badge_count
   FROM users u
   LEFT JOIN badges b ON b.userid = u.id
   GROUP BY u.id
),
user_votes_cast AS (
   SELECT u.id AS user_id,
          COUNT(v.id) AS votes_cast,
          COALESCE(SUM(v.bountyamount), 0) AS total_bounty_cast
   FROM users u
   LEFT JOIN votes v ON v.userid = u.id
   GROUP BY u.id
),
user_votes_received AS (
   SELECT u.id AS user_id,
          COUNT(v.id) AS votes_received,
          COALESCE(SUM(v.bountyamount), 0) AS total_bounty_received
   FROM users u
   LEFT JOIN posts p ON p.owneruserid = u.id
   LEFT JOIN votes v ON v.postid = p.id
   GROUP BY u.id
),
user_comments_made AS (
   SELECT u.id AS user_id,
          COUNT(c.id) AS comments_made
   FROM users u
   LEFT JOIN comments c ON c.userid = u.id
   GROUP BY u.id
),
user_comments_received AS (
   SELECT u.id AS user_id,
          COUNT(c.id) AS comments_received
   FROM users u
   LEFT JOIN posts p ON p.owneruserid = u.id
   LEFT JOIN comments c ON c.postid = p.id
   GROUP BY u.id
)
SELECT up.user_id,
       up.reputation,
       up.post_count,
       up.total_post_score,
       up.total_viewcount,
       up.total_favoritecount,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(uvc.votes_cast, 0) AS votes_cast,
       COALESCE(uvc.total_bounty_cast, 0) AS total_bounty_cast,
       COALESCE(uvr.votes_received, 0) AS votes_received,
       COALESCE(uvr.total_bounty_received, 0) AS total_bounty_received,
       COALESCE(ucm.comments_made, 0) AS comments_made,
       COALESCE(ucr.comments_received, 0) AS comments_received
FROM user_posts up
LEFT JOIN user_badges ub ON ub.user_id = up.user_id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = up.user_id
LEFT JOIN user_votes_received uvr ON uvr.user_id = up.user_id
LEFT JOIN user_comments_made ucm ON ucm.user_id = up.user_id
LEFT JOIN user_comments_received ucr ON ucr.user_id = up.user_id
ORDER BY up.reputation DESC
LIMIT 10
