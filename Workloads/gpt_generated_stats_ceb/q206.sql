WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(CASE WHEN posttypeid = 2 THEN 1 ELSE 0 END) AS answer_post_count,
        SUM(score) AS total_score,
        SUM(viewcount) AS total_views,
        AVG(score) AS avg_score,
        MAX(creationdate) AS latest_post_creation
    FROM posts
    GROUP BY owneruserid
),
user_votes AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS vote_cast_count,
        COUNT(DISTINCT votetypeid) AS distinct_vote_type_count
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count,
        MIN(date) AS earliest_badge_date,
        MAX(date) AS latest_badge_date
    FROM badges
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.answer_post_count, 0) AS answer_post_count,
    COALESCE(p.total_score, 0) AS total_score,
    COALESCE(p.total_views, 0) AS total_views,
    COALESCE(p.avg_score, 0) AS avg_score,
    COALESCE(p.latest_post_creation, TIMESTAMP '1970-01-01 00:00:00 UTC') AS latest_post_creation,
    COALESCE(v.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(v.distinct_vote_type_count, 0) AS distinct_vote_type_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    b.earliest_badge_date,
    b.latest_badge_date
FROM users u
LEFT JOIN user_posts p ON p.user_id = u.id
LEFT JOIN user_votes v ON v.user_id = u.id
LEFT JOIN user_badges b ON b.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
