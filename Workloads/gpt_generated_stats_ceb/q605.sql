WITH
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            SUM(viewcount) AS total_viewcount,
            AVG(score) AS avg_post_score
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comment_count,
            SUM(score) AS total_comment_score,
            AVG(score) AS avg_comment_score
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS vote_count,
            COUNT(DISTINCT votetypeid) AS distinct_vote_types,
            SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    )
SELECT
    u.id,
    u.reputation,
    u.creationdate,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(c.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.distinct_vote_types, 0) AS distinct_vote_types,
    COALESCE(v.upvote_count, 0) AS upvote_count,
    COALESCE(v.downvote_count, 0) AS downvote_count,
    COALESCE(b.badge_count, 0) AS badge_count
FROM users u
LEFT JOIN user_posts p ON p.user_id = u.id
LEFT JOIN user_comments c ON c.user_id = u.id
LEFT JOIN user_votes v ON v.user_id = u.id
LEFT JOIN user_badges b ON b.user_id = u.id
ORDER BY (
        COALESCE(p.post_count, 0) +
        COALESCE(c.comment_count, 0) +
        COALESCE(v.vote_count, 0) +
        COALESCE(b.badge_count, 0)
    ) DESC
LIMIT 20
