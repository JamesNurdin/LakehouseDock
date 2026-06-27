WITH user_post_stats AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(score) AS total_post_score,
        SUM(viewcount) AS total_viewcount,
        SUM(answercount) AS total_answercount,
        SUM(commentcount) AS total_commentcount,
        SUM(favoritecount) AS total_favoritecount
    FROM posts
    GROUP BY owneruserid
),
user_comment_stats AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count,
        SUM(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_vote_cast_stats AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS vote_cast_count,
        SUM(COALESCE(bountyamount, 0)) AS total_bounty_cast
    FROM votes
    GROUP BY userid
),
user_vote_received_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS vote_received_count,
        SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badge_stats AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_history_stats AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS history_event_count
    FROM posthistory
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_answercount, 0) AS total_answercount,
    COALESCE(up.total_commentcount, 0) AS total_commentcount,
    COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uvc.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(uvc.total_bounty_cast, 0) AS total_bounty_cast,
    COALESCE(uvr.vote_received_count, 0) AS vote_received_count,
    COALESCE(uvr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uh.history_event_count, 0) AS history_event_count
FROM users u
LEFT JOIN user_post_stats up ON u.id = up.user_id
LEFT JOIN user_comment_stats uc ON u.id = uc.user_id
LEFT JOIN user_vote_cast_stats uvc ON u.id = uvc.user_id
LEFT JOIN user_vote_received_stats uvr ON u.id = uvr.user_id
LEFT JOIN user_badge_stats ub ON u.id = ub.user_id
LEFT JOIN user_history_stats uh ON u.id = uh.user_id
ORDER BY u.reputation DESC
LIMIT 100
