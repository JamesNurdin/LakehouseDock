WITH
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS total_posts,
            COALESCE(SUM(score), 0) AS total_post_score,
            AVG(score) AS avg_post_score,
            COALESCE(SUM(answercount), 0) AS total_answers
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_comments,
            COALESCE(SUM(score), 0) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_votes_cast
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_badges
        FROM badges
        GROUP BY userid
    ),
    user_edits AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_edits
        FROM posthistory
        GROUP BY userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(uc.total_comments, 0) AS total_comments,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uvc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(uvr.total_votes_received, 0) AS total_votes_received,
    COALESCE(ub.total_badges, 0) AS total_badges,
    COALESCE(ue.total_edits, 0) AS total_edits
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
ORDER BY total_posts DESC, u.id
LIMIT 100
