WITH
    user_posts AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            SUM(viewcount) AS total_views,
            SUM(answercount) AS total_answer_count,
            SUM(commentcount) AS total_comment_count,
            SUM(favoritecount) AS total_favorite_count
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid,
            COUNT(*) AS comment_count,
            AVG(score) AS avg_comment_score,
            SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT
            userid,
            COUNT(*) AS votes_cast
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
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
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(DISTINCT t.id) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_count, 0) AS total_comment_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(ut.tag_count, 0) AS tag_count,
    -- Derived metrics
    CASE WHEN COALESCE(up.post_count, 0) = 0 THEN 0
         ELSE COALESCE(up.total_post_score, 0) / COALESCE(up.post_count, 1)
    END AS avg_post_score,
    CASE WHEN COALESCE(up.post_count, 0) = 0 THEN 0
         ELSE COALESCE(uvr.votes_received, 0) / COALESCE(up.post_count, 1)
    END AS votes_received_per_post,
    (COALESCE(up.total_post_score, 0) + COALESCE(uc.total_comment_score, 0) + COALESCE(uvr.votes_received, 0) + COALESCE(ub.badge_count, 0) * 10) AS engagement_score
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
LEFT JOIN user_tags ut ON ut.userid = u.id
ORDER BY engagement_score DESC
LIMIT 20
