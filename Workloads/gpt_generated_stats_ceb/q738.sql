/*
   User activity snapshot:
   - Posts owned, scores, views
   - Comments made
   - Votes cast and received
   - Badges earned
   - Distinct tags used in owned posts
   - Number of post links from owned posts
   Sorted by reputation.
*/
WITH user_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_score,
        COALESCE(AVG(p.score), 0) AS avg_score,
        COALESCE(SUM(p.viewcount), 0) AS total_views
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid,
        COUNT(*) AS comment_count
    FROM comments c
    GROUP BY c.userid
),
user_votes_cast AS (
    SELECT
        v.userid,
        COUNT(*) AS votes_cast
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS votes_received
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
),
user_tags AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_postlinks AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_score, 0) AS total_post_score,
    COALESCE(up.avg_score, 0) AS avg_post_score,
    COALESCE(up.total_views, 0) AS total_post_views,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(upk.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_tags ut ON ut.userid = u.id
LEFT JOIN user_postlinks upk ON upk.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
