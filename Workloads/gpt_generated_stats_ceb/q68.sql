WITH
    user_base AS (
        SELECT
            id AS user_id,
            reputation,
            creationdate,
            views,
            upvotes,
            downvotes
        FROM users
    ),
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            COALESCE(SUM(score), 0) AS total_post_score,
            COALESCE(SUM(viewcount), 0) AS total_viewcount
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comment_count,
            COALESCE(SUM(score), 0) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS votes_cast_count
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received_count
        FROM votes v
        JOIN posts p
            ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_posthistory AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    )
SELECT
    ub.user_id,
    ub.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(ubad.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    (
        COALESCE(up.total_post_score, 0)
        + COALESCE(uc.total_comment_score, 0)
        + COALESCE(uvc.votes_cast_count, 0)
        + COALESCE(uvr.votes_received_count, 0)
        + COALESCE(ubad.badge_count, 0)
        + COALESCE(uph.posthistory_count, 0)
    ) AS contribution_score
FROM user_base ub
LEFT JOIN user_posts up
    ON ub.user_id = up.user_id
LEFT JOIN user_comments uc
    ON ub.user_id = uc.user_id
LEFT JOIN user_votes_cast uvc
    ON ub.user_id = uvc.user_id
LEFT JOIN user_votes_received uvr
    ON ub.user_id = uvr.user_id
LEFT JOIN user_badges ubad
    ON ub.user_id = ubad.user_id
LEFT JOIN user_posthistory uph
    ON ub.user_id = uph.user_id
ORDER BY contribution_score DESC
LIMIT 10
