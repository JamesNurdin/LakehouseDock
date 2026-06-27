WITH
    user_posts AS (
        SELECT
            u.id AS user_id,
            COUNT(p.id) AS post_count,
            SUM(p.score) AS post_score_sum,
            AVG(p.score) AS post_score_avg,
            SUM(p.viewcount) AS total_viewcount,
            SUM(p.answercount) AS total_answercount,
            SUM(p.commentcount) AS total_commentcount,
            SUM(p.favoritecount) AS total_favoritecount
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        GROUP BY u.id
    ),
    user_comments AS (
        SELECT
            u.id AS user_id,
            COUNT(c.id) AS comment_count,
            SUM(c.score) AS comment_score_sum,
            AVG(c.score) AS comment_score_avg
        FROM users u
        LEFT JOIN comments c ON c.userid = u.id
        GROUP BY u.id
    ),
    user_votes_cast AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS votes_cast,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
        FROM users u
        LEFT JOIN votes v ON v.userid = u.id
        GROUP BY u.id
    ),
    user_votes_received AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS votes_received,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY u.id
    ),
    user_posthistory AS (
        SELECT
            u.id AS user_id,
            COUNT(ph.id) AS posthistory_count,
            SUM(CASE WHEN ph.posthistorytypeid = 2 THEN 1 ELSE 0 END) AS edit_events
        FROM users u
        LEFT JOIN posthistory ph ON ph.userid = u.id
        GROUP BY u.id
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_score_avg, 0) AS post_score_avg,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_answercount, 0) AS total_answercount,
    COALESCE(up.total_commentcount, 0) AS total_commentcount,
    COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uc.comment_score_avg, 0) AS comment_score_avg,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(uvc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
    COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(uph.edit_events, 0) AS edit_events
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
ORDER BY post_count DESC
LIMIT 100
