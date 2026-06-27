WITH user_post_stats AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COALESCE(SUM(p.viewcount), 0) AS total_view_count,
           COALESCE(SUM(p.favoritecount), 0) AS total_favorite_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comment_stats AS (
    SELECT u.id AS user_id,
           COUNT(c.id) AS comment_count,
           COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_badge_stats AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_vote_stats AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS vote_count,
           COALESCE(SUM(v.bountyamount), 0) AS total_bounty_amount
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_posthistory_stats AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS posthistory_event_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_received_vote_stats AS (
    SELECT u.id AS user_id,
           COUNT(v.id) AS received_vote_count,
           COALESCE(SUM(v.bountyamount), 0) AS received_bounty_total
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       up.post_count,
       up.total_post_score,
       CASE WHEN up.post_count > 0 THEN up.total_post_score / up.post_count ELSE NULL END AS avg_post_score,
       up.total_view_count,
       up.total_favorite_count,
       uc.comment_count,
       uc.total_comment_score,
       CASE WHEN uc.comment_count > 0 THEN uc.total_comment_score / uc.comment_count ELSE NULL END AS avg_comment_score,
       ub.badge_count,
       uv.vote_count,
       uv.total_bounty_amount,
       uph.posthistory_event_count,
       rv.received_vote_count,
       rv.received_bounty_total,
       CASE WHEN up.post_count > 0 THEN rv.received_vote_count / up.post_count ELSE NULL END AS avg_votes_per_post
FROM users u
LEFT JOIN user_post_stats up ON up.user_id = u.id
LEFT JOIN user_comment_stats uc ON uc.user_id = u.id
LEFT JOIN user_badge_stats ub ON ub.user_id = u.id
LEFT JOIN user_vote_stats uv ON uv.user_id = u.id
LEFT JOIN user_posthistory_stats uph ON uph.user_id = u.id
LEFT JOIN user_received_vote_stats rv ON rv.user_id = u.id
ORDER BY up.total_post_score DESC
LIMIT 10
