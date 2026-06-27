WITH
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS total_posts,
            SUM(CASE WHEN posttypeid = 1 THEN 1 ELSE 0 END) AS total_questions,
            SUM(CASE WHEN posttypeid = 2 THEN 1 ELSE 0 END) AS total_answers,
            SUM(score) AS total_post_score,
            AVG(score) AS avg_post_score,
            SUM(viewcount) AS total_views
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_comments,
            SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_votes_cast,
            SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS total_upvotes_cast,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS total_downvotes_cast
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS total_votes_received,
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS total_upvotes_received,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS total_downvotes_received
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
    user_tags AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS total_tags
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_posthistory AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_posthistory_events
        FROM posthistory
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
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(uc.total_comments, 0) AS total_comments,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uvc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(uvc.total_upvotes_cast, 0) AS total_upvotes_cast,
    COALESCE(uvc.total_downvotes_cast, 0) AS total_downvotes_cast,
    COALESCE(uvr.total_votes_received, 0) AS total_votes_received,
    COALESCE(uvr.total_upvotes_received, 0) AS total_upvotes_received,
    COALESCE(uvr.total_downvotes_received, 0) AS total_downvotes_received,
    COALESCE(ub.total_badges, 0) AS total_badges,
    COALESCE(ut.total_tags, 0) AS total_tags,
    COALESCE(uph.total_posthistory_events, 0) AS total_posthistory_events
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
