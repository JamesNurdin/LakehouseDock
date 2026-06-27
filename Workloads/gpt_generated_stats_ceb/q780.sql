WITH
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            AVG(score) AS avg_post_score,
            SUM(answercount) AS total_answer_count,
            SUM(commentcount) AS total_comment_count,
            SUM(viewcount) AS total_view_count
        FROM posts
        GROUP BY owneruserid
    ),
    user_badges AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_comments AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comment_count,
            AVG(score) AS avg_comment_score
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS votes_cast
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_history AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS history_events
        FROM posthistory
        GROUP BY userid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS tag_association_count,
            SUM(t.count) AS tag_total_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_count, 0) AS total_comment_count,
    COALESCE(up.total_view_count, 0) AS total_view_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uh.history_events, 0) AS history_events,
    COALESCE(ut.tag_association_count, 0) AS tag_association_count,
    COALESCE(ut.tag_total_count, 0) AS tag_total_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_history uh ON uh.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 20
