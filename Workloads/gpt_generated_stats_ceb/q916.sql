WITH
    user_posts AS (
        SELECT
            u.id AS user_id,
            u.reputation,
            COUNT(p.id) AS post_count,
            SUM(p.score) AS total_post_score,
            AVG(p.score) AS avg_post_score,
            SUM(p.viewcount) AS total_viewcount,
            SUM(p.answercount) AS total_answer_count,
            SUM(p.commentcount) AS total_comment_count,
            SUM(p.favoritecount) AS total_favorite_count
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        GROUP BY u.id, u.reputation
    ),
    user_comments AS (
        SELECT
            u.id AS user_id,
            COUNT(c.id) AS comment_made_count,
            SUM(c.score) AS total_comment_score
        FROM users u
        LEFT JOIN comments c ON c.userid = u.id
        GROUP BY u.id
    ),
    user_votes_cast AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS votes_cast_count,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
        FROM users u
        LEFT JOIN votes v ON v.userid = u.id
        GROUP BY u.id
    ),
    user_votes_received AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS votes_received_count,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY u.id
    ),
    user_badges AS (
        SELECT
            u.id AS user_id,
            COUNT(b.id) AS badge_count
        FROM users u
        LEFT JOIN badges b ON b.userid = u.id
        GROUP BY u.id
    ),
    user_edits AS (
        SELECT
            u.id AS user_id,
            COUNT(ph.id) AS edit_count
        FROM users u
        LEFT JOIN posthistory ph ON ph.userid = u.id
        GROUP BY u.id
    ),
    user_links AS (
        SELECT
            u.id AS user_id,
            COUNT(pl.id) AS postlink_count
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN postlinks pl ON pl.postid = p.id
        GROUP BY u.id
    )
SELECT
    up.user_id,
    up.reputation,
    up.post_count,
    up.total_post_score,
    up.avg_post_score,
    up.total_viewcount,
    up.total_answer_count,
    up.total_comment_count,
    up.total_favorite_count,
    uc.comment_made_count,
    uc.total_comment_score,
    uv_cast.votes_cast_count,
    uv_cast.upvotes_cast,
    uv_cast.downvotes_cast,
    uv_recv.votes_received_count,
    uv_recv.upvotes_received,
    uv_recv.downvotes_received,
    ub.badge_count,
    ue.edit_count,
    ul.postlink_count
FROM user_posts up
LEFT JOIN user_comments uc ON uc.user_id = up.user_id
LEFT JOIN user_votes_cast uv_cast ON uv_cast.user_id = up.user_id
LEFT JOIN user_votes_received uv_recv ON uv_recv.user_id = up.user_id
LEFT JOIN user_badges ub ON ub.user_id = up.user_id
LEFT JOIN user_edits ue ON ue.user_id = up.user_id
LEFT JOIN user_links ul ON ul.user_id = up.user_id
ORDER BY up.reputation DESC
LIMIT 100
