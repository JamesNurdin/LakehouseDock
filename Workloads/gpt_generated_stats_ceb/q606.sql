WITH user_posts AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS total_posts,
        SUM(score) AS total_post_score,
        AVG(score) AS avg_post_score,
        SUM(CASE WHEN posttypeid = 1 THEN 1 ELSE 0 END) AS total_questions,
        SUM(CASE WHEN posttypeid = 2 THEN 1 ELSE 0 END) AS total_answers
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid,
        COUNT(*) AS total_comments_written,
        SUM(score) AS total_comment_score,
        AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT
        userid,
        COUNT(*) AS total_votes_cast
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(v.id) AS total_votes_received
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        userid,
        COUNT(*) AS total_badges
    FROM badges
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(up.total_questions, 0) AS total_questions,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(uc.total_comments_written, 0) AS total_comments_written,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(uvc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(uvr.total_votes_received, 0) AS total_votes_received,
    COALESCE(ub.total_badges, 0) AS total_badges
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
ORDER BY total_posts DESC, total_badges DESC
LIMIT 100
