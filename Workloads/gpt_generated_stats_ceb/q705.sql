WITH user_posts AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            AVG(score) AS avg_post_score,
            SUM(answercount) AS total_answer_count,
            SUM(commentcount) AS total_post_comment_count,
            SUM(viewcount) AS total_view_count
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid,
            COUNT(*) AS comment_count,
            SUM(score) AS total_comment_score,
            AVG(score) AS avg_comment_score
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT
            userid,
            COUNT(*) AS vote_count,
            SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_edits AS (
        SELECT
            userid,
            COUNT(*) AS edit_count
        FROM posthistory
        GROUP BY userid
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
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_answer_count, 0) AS total_answer_count,
    COALESCE(p.total_post_comment_count, 0) AS total_post_comment_count,
    COALESCE(p.total_view_count, 0) AS total_view_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(c.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.upvote_count, 0) AS upvote_count,
    COALESCE(v.downvote_count, 0) AS downvote_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    (
        u.reputation
        + COALESCE(p.total_post_score, 0)
        + COALESCE(c.total_comment_score, 0)
        + COALESCE(v.upvote_count, 0) * 10
        - COALESCE(v.downvote_count, 0) * 5
        + COALESCE(b.badge_count, 0) * 20
        + COALESCE(e.edit_count, 0) * 5
    ) AS activity_score
FROM users u
LEFT JOIN user_posts p ON p.userid = u.id
LEFT JOIN user_comments c ON c.userid = u.id
LEFT JOIN user_votes v ON v.userid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
LEFT JOIN user_edits e ON e.userid = u.id
ORDER BY activity_score DESC
LIMIT 10
