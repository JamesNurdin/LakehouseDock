WITH user_activity AS (
    SELECT
        u.id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes,
        COUNT(DISTINCT b.id) AS badge_count,
        MAX(b.date) AS latest_badge_date,
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(DISTINCT c.postid) AS distinct_commented_posts,
        COALESCE(SUM(c.score), 0) AS total_comment_score,
        AVG(c.score) AS avg_comment_score,
        COUNT(DISTINCT v.id) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_given,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_given,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_amount
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    LEFT JOIN comments c ON c.userid = u.id
    LEFT JOIN votes v ON v.userid = u.id
    WHERE u.reputation >= 1000
    GROUP BY u.id, u.reputation, u.creationdate, u.views, u.upvotes, u.downvotes
)
SELECT
    id AS user_id,
    reputation,
    creationdate,
    views,
    upvotes,
    downvotes,
    badge_count,
    latest_badge_date,
    comment_count,
    distinct_commented_posts,
    total_comment_score,
    avg_comment_score,
    vote_count,
    upvote_given,
    downvote_given,
    total_bounty_amount
FROM user_activity
ORDER BY badge_count DESC, total_comment_score DESC
LIMIT 100
