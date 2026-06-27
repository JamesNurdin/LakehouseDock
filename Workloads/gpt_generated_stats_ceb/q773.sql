WITH
    user_posts AS (
        SELECT
            u.id AS user_id,
            u.reputation,
            COUNT(p.id) AS post_count,
            COALESCE(SUM(p.score), 0) AS total_post_score,
            COALESCE(SUM(p.viewcount), 0) AS total_view_count,
            AVG(p.score) AS avg_post_score
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        GROUP BY u.id, u.reputation
    ),
    user_comments AS (
        SELECT
            u.id AS user_id,
            COUNT(c.id) AS comment_count,
            COALESCE(SUM(c.score), 0) AS total_comment_score
        FROM users u
        LEFT JOIN comments c ON c.userid = u.id
        GROUP BY u.id
    ),
    user_votes AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS vote_count,
            COALESCE(SUM(v.bountyamount), 0) AS total_bounty_amount
        FROM users u
        LEFT JOIN votes v ON v.userid = u.id
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
    user_tags AS (
        SELECT
            u.id AS user_id,
            COUNT(DISTINCT t.id) AS tag_count
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN tags t ON t.excerptpostid = p.id
        GROUP BY u.id
    ),
    user_post_edits AS (
        SELECT
            u.id AS user_id,
            COUNT(ph.id) AS post_edit_count
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        LEFT JOIN posthistory ph ON ph.posthistorytypeid = p.id
        GROUP BY u.id
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_view_count, 0) AS total_view_count,
    up.avg_post_score,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(ue.post_edit_count, 0) AS post_edit_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes uv ON uv.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_post_edits ue ON ue.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 10
