WITH
    user_posts AS (
        SELECT
            u.id AS user_id,
            COUNT(p.id) AS post_count,
            COALESCE(SUM(p.score), 0) AS post_score_sum,
            COALESCE(SUM(p.viewcount), 0) AS total_views,
            COALESCE(SUM(p.favoritecount), 0) AS total_favorites
        FROM users u
        LEFT JOIN posts p
            ON p.owneruserid = u.id
        GROUP BY u.id
    ),
    user_comments AS (
        SELECT
            u.id AS user_id,
            COUNT(c.id) AS comment_count,
            COALESCE(SUM(c.score), 0) AS comment_score_sum
        FROM users u
        LEFT JOIN comments c
            ON c.userid = u.id
        GROUP BY u.id
    ),
    user_votes_cast AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS votes_cast_count,
            COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvotes_cast,
            COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvotes_cast
        FROM users u
        LEFT JOIN votes v
            ON v.userid = u.id
        GROUP BY u.id
    ),
    user_votes_received AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS votes_received_count,
            COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvotes_received,
            COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvotes_received
        FROM users u
        LEFT JOIN posts p
            ON p.owneruserid = u.id
        LEFT JOIN votes v
            ON v.postid = p.id
        GROUP BY u.id
    ),
    user_badges AS (
        SELECT
            u.id AS user_id,
            COUNT(b.id) AS badge_count
        FROM users u
        LEFT JOIN badges b
            ON b.userid = u.id
        GROUP BY u.id
    )
SELECT
    u.id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(uvc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
    COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
    COALESCE(ub.badge_count, 0) AS badge_count
FROM users u
LEFT JOIN user_posts up
    ON up.user_id = u.id
LEFT JOIN user_comments uc
    ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc
    ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr
    ON uvr.user_id = u.id
LEFT JOIN user_badges ub
    ON ub.user_id = u.id
ORDER BY post_score_sum DESC
LIMIT 10
