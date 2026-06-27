WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(score) AS total_score,
        AVG(score) AS avg_score,
        SUM(viewcount) AS total_views,
        SUM(answercount) AS total_answers,
        SUM(commentcount) AS total_comments,
        SUM(favoritecount) AS total_favorites
    FROM posts
    WHERE posttypeid = 1
    GROUP BY owneruserid
),
user_votes AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(CASE WHEN votetypeid = 3 THEN bountyamount ELSE 0 END) AS total_bounty_given
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count,
        MIN(date) AS first_badge_date,
        MAX(date) AS last_badge_date
    FROM badges
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_score, 0) AS total_score,
    COALESCE(p.avg_score, 0) AS avg_score,
    COALESCE(p.total_views, 0) AS total_views,
    COALESCE(p.total_answers, 0) AS total_answers,
    COALESCE(p.total_comments, 0) AS total_comments,
    COALESCE(p.total_favorites, 0) AS total_favorites,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.upvote_count, 0) AS upvote_count,
    COALESCE(v.downvote_count, 0) AS downvote_count,
    COALESCE(v.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(b.badge_count, 0) AS badge_count,
    b.first_badge_date,
    b.last_badge_date
FROM users u
LEFT JOIN user_posts p
    ON u.id = p.user_id
LEFT JOIN user_votes v
    ON u.id = v.user_id
LEFT JOIN user_badges b
    ON u.id = b.user_id
WHERE u.reputation > 1000
ORDER BY total_score DESC
LIMIT 20
