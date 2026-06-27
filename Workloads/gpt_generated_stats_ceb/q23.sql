WITH post_stats AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        COALESCE(SUM(score), 0) AS total_post_score,
        COALESCE(SUM(viewcount), 0) AS total_post_views,
        COALESCE(SUM(answercount), 0) AS total_answer_count,
        COALESCE(SUM(commentcount), 0) AS total_post_comment_count
    FROM posts
    GROUP BY owneruserid
),
comment_stats AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count,
        COALESCE(SUM(score), 0) AS total_comment_score
    FROM comments
    GROUP BY userid
),
vote_stats AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS vote_cast_count,
        COALESCE(SUM(bountyamount), 0) AS total_bounty_given
    FROM votes
    GROUP BY userid
),
badge_stats AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
edit_stats AS (
    SELECT
        lasteditoruserid AS user_id,
        COUNT(*) AS edit_count
    FROM posts
    GROUP BY lasteditoruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_post_views, 0) AS total_post_views,
    COALESCE(p.total_answer_count, 0) AS total_answer_count,
    COALESCE(p.total_post_comment_count, 0) AS total_post_comment_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(v.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(v.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    CASE WHEN COALESCE(p.post_count, 0) > 0 THEN COALESCE(p.total_post_score, 0) * 1.0 / p.post_count ELSE NULL END AS avg_post_score,
    CASE WHEN COALESCE(p.post_count, 0) > 0 THEN COALESCE(p.total_post_views, 0) * 1.0 / p.post_count ELSE NULL END AS avg_post_views
FROM users u
LEFT JOIN post_stats p ON p.user_id = u.id
LEFT JOIN comment_stats c ON c.user_id = u.id
LEFT JOIN vote_stats v ON v.user_id = u.id
LEFT JOIN badge_stats b ON b.user_id = u.id
LEFT JOIN edit_stats e ON e.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
