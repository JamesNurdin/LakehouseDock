WITH
    user_badges AS (
        SELECT
            users.id,
            COUNT(badges.id) AS badge_count
        FROM users
        LEFT JOIN badges ON badges.userid = users.id
        GROUP BY users.id
    ),
    user_posts AS (
        SELECT
            users.id,
            COUNT(posts.id) AS post_count,
            COUNT(CASE WHEN posts.posttypeid = 2 THEN 1 END) AS answer_post_count,
            SUM(posts.score) AS total_post_score,
            AVG(posts.score) AS avg_post_score
        FROM users
        LEFT JOIN posts ON posts.owneruserid = users.id
        GROUP BY users.id
    ),
    user_comments AS (
        SELECT
            users.id,
            COUNT(comments.id) AS comment_count
        FROM users
        LEFT JOIN comments ON comments.userid = users.id
        GROUP BY users.id
    ),
    user_votes_cast AS (
        SELECT
            users.id,
            COUNT(votes.id) AS votes_cast_count
        FROM users
        LEFT JOIN votes ON votes.userid = users.id
        GROUP BY users.id
    ),
    user_votes_received AS (
        SELECT
            users.id,
            COUNT(votes.id) AS votes_received_count
        FROM users
        LEFT JOIN posts ON posts.owneruserid = users.id
        LEFT JOIN votes ON votes.postid = posts.id
        GROUP BY users.id
    ),
    user_edits AS (
        SELECT
            users.id,
            COUNT(posts.id) AS edit_count
        FROM users
        LEFT JOIN posts ON posts.lasteditoruserid = users.id
        GROUP BY users.id
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.answer_post_count, 0) AS answer_post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(ue.edit_count, 0) AS edit_count
FROM users u
LEFT JOIN user_badges ub ON ub.id = u.id
LEFT JOIN user_posts up ON up.id = u.id
LEFT JOIN user_comments uc ON uc.id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.id = u.id
LEFT JOIN user_votes_received uvr ON uvr.id = u.id
LEFT JOIN user_edits ue ON ue.id = u.id
ORDER BY u.reputation DESC
LIMIT 100
