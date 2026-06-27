WITH
    user_posts AS (
        SELECT
            u.id AS user_id,
            COUNT(p.id) AS post_count,
            COALESCE(SUM(p.score), 0) AS total_post_score,
            COALESCE(SUM(p.viewcount), 0) AS total_post_views,
            COALESCE(SUM(p.answercount), 0) AS total_answer_count,
            COALESCE(SUM(p.commentcount), 0) AS total_comment_count,
            COALESCE(SUM(p.favoritecount), 0) AS total_favorite_count
        FROM users u
        LEFT JOIN posts p
            ON p.owneruserid = u.id
        GROUP BY u.id
    ),
    user_comments AS (
        SELECT
            u.id AS user_id,
            COUNT(c.id) AS comment_count,
            COALESCE(SUM(c.score), 0) AS total_comment_score
        FROM users u
        LEFT JOIN comments c
            ON c.userid = u.id
        GROUP BY u.id
    ),
    user_votes_cast AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS votes_cast_count,
            COALESCE(SUM(v.bountyamount), 0) AS total_bounty_amount_cast
        FROM users u
        LEFT JOIN votes v
            ON v.userid = u.id
        GROUP BY u.id
    ),
    user_votes_received AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS votes_received_count,
            COALESCE(SUM(v.bountyamount), 0) AS total_bounty_amount_received
        FROM users u
        LEFT JOIN posts p
            ON p.owneruserid = u.id
        LEFT JOIN votes v
            ON v.postid = p.id
        GROUP BY u.id
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
    COALESCE(up.total_post_views, 0) AS total_post_views,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_count, 0) AS total_comment_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvc.total_bounty_amount_cast, 0) AS total_bounty_amount_cast,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(uvr.total_bounty_amount_received, 0) AS total_bounty_amount_received
FROM users u
LEFT JOIN user_posts up
    ON up.user_id = u.id
LEFT JOIN user_comments uc
    ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc
    ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr
    ON uvr.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 100
