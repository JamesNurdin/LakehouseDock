WITH user_posts AS (
  SELECT u.id AS user_id,
         COUNT(p.id) AS post_count,
         COALESCE(SUM(p.score), 0) AS post_score_sum,
         COALESCE(AVG(p.score), 0) AS post_score_avg,
         COALESCE(SUM(p.viewcount), 0) AS post_view_sum
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  GROUP BY u.id
),
user_tags AS (
  SELECT u.id AS user_id,
         COUNT(t.id) AS tag_count
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  LEFT JOIN tags t ON t.excerptpostid = p.id
  GROUP BY u.id
),
user_links AS (
  SELECT u.id AS user_id,
         COUNT(pl.id) AS link_count
  FROM users u
  LEFT JOIN posts p ON p.owneruserid = u.id
  LEFT JOIN postlinks pl ON pl.postid = p.id
  GROUP BY u.id
),
user_comments AS (
  SELECT u.id AS user_id,
         COUNT(c.id) AS comment_count,
         COALESCE(SUM(c.score), 0) AS comment_score_sum
  FROM users u
  LEFT JOIN comments c ON c.userid = u.id
  GROUP BY u.id
),
user_votes AS (
  SELECT u.id AS user_id,
         COUNT(v.id) AS vote_cast_count,
         COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_cast,
         COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_cast,
         COALESCE(SUM(v.bountyamount), 0) AS bounty_given_sum
  FROM users u
  LEFT JOIN votes v ON v.userid = u.id
  GROUP BY u.id
),
user_badges AS (
  SELECT u.id AS user_id,
         COUNT(b.id) AS badge_count
  FROM users u
  LEFT JOIN badges b ON b.userid = u.id
  GROUP BY u.id
),
user_history AS (
  SELECT u.id AS user_id,
         COUNT(ph.id) AS post_history_count
  FROM users u
  LEFT JOIN posthistory ph ON ph.userid = u.id
  GROUP BY u.id
),
user_activity AS (
  SELECT u.id AS user_id,
         u.reputation,
         COALESCE(up.post_count, 0) AS post_count,
         COALESCE(uc.comment_count, 0) AS comment_count,
         COALESCE(uv.vote_cast_count, 0) AS vote_cast_count,
         COALESCE(ub.badge_count, 0) AS badge_count,
         COALESCE(ut.tag_count, 0) AS tag_count,
         COALESCE(ul.link_count, 0) AS link_count,
         (COALESCE(up.post_count, 0) * 2
          + COALESCE(uc.comment_count, 0)
          + COALESCE(uv.vote_cast_count, 0)
          + COALESCE(ub.badge_count, 0) * 3
          + COALESCE(ut.tag_count, 0) * 4
          + COALESCE(ul.link_count, 0) * 2) AS activity_score
  FROM users u
  LEFT JOIN user_posts up ON up.user_id = u.id
  LEFT JOIN user_comments uc ON uc.user_id = u.id
  LEFT JOIN user_votes uv ON uv.user_id = u.id
  LEFT JOIN user_badges ub ON ub.user_id = u.id
  LEFT JOIN user_tags ut ON ut.user_id = u.id
  LEFT JOIN user_links ul ON ul.user_id = u.id
)
SELECT user_id,
       reputation,
       post_count,
       comment_count,
       vote_cast_count,
       badge_count,
       tag_count,
       link_count,
       activity_score
FROM user_activity
ORDER BY activity_score DESC
LIMIT 50
