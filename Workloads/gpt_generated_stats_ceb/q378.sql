WITH user_reputation AS (
    SELECT u.id AS user_id,
           u.reputation
    FROM users u
),
user_post_metrics AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COALESCE(SUM(p.viewcount), 0) AS total_views
    FROM posts p
    GROUP BY p.owneruserid
),
user_tag_metrics AS (
    SELECT p.owneruserid AS user_id,
           COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM posts p
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT userid, COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_comments AS (
    SELECT userid, COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT userid, COUNT(*) AS vote_cast_count
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT p.owneruserid AS user_id,
           COUNT(v.id) AS vote_received_count
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
)
SELECT ur.user_id,
       ur.reputation,
       COALESCE(upm.post_count, 0) AS post_count,
       COALESCE(upm.total_post_score, 0) AS total_post_score,
       COALESCE(upm.total_views, 0) AS total_views,
       COALESCE(utm.distinct_tag_count, 0) AS distinct_tag_count,
       COALESCE(ub.badge_count, 0) AS badge_count,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uvc.vote_cast_count, 0) AS vote_cast_count,
       COALESCE(uvr.vote_received_count, 0) AS vote_received_count
FROM user_reputation ur
LEFT JOIN user_post_metrics upm ON upm.user_id = ur.user_id
LEFT JOIN user_tag_metrics utm ON utm.user_id = ur.user_id
LEFT JOIN user_badges ub ON ub.userid = ur.user_id
LEFT JOIN user_comments uc ON uc.userid = ur.user_id
LEFT JOIN user_votes_cast uvc ON uvc.userid = ur.user_id
LEFT JOIN user_votes_received uvr ON uvr.user_id = ur.user_id
ORDER BY ur.reputation DESC
LIMIT 100
