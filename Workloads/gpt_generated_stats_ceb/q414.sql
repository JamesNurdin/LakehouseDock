WITH
    user_posts AS (
        SELECT
            u.id AS user_id,
            COUNT(p.id) AS post_count,
            SUM(p.score) AS post_score_sum,
            AVG(p.score) AS post_score_avg,
            SUM(p.viewcount) AS total_views,
            SUM(p.favoritecount) AS total_favorites
        FROM users u
        LEFT JOIN posts p ON p.owneruserid = u.id
        GROUP BY u.id
    ),
    user_comments AS (
        SELECT
            u.id AS user_id,
            COUNT(c.id) AS comment_count,
            SUM(c.score) AS comment_score_sum
        FROM users u
        LEFT JOIN comments c ON c.userid = u.id
        GROUP BY u.id
    ),
    user_votes AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS vote_count,
            SUM(v.bountyamount) AS total_bounty
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
    user_posthistory AS (
        SELECT
            u.id AS user_id,
            COUNT(ph.id) AS posthistory_count
        FROM users u
        LEFT JOIN posthistory ph ON ph.userid = u.id
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
    user_edits AS (
        SELECT
            u.id AS user_id,
            COUNT(p.id) AS edit_count
        FROM users u
        LEFT JOIN posts p ON p.lasteditoruserid = u.id
        GROUP BY u.id
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_score_avg, 0) AS post_score_avg,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.total_bounty, 0) AS total_bounty,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(ue.edit_count, 0) AS edit_count
FROM users u
LEFT JOIN user_posts up        ON up.user_id = u.id
LEFT JOIN user_comments uc    ON uc.user_id = u.id
LEFT JOIN user_votes uv       ON uv.user_id = u.id
LEFT JOIN user_badges ub      ON ub.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_tags ut        ON ut.user_id = u.id
LEFT JOIN user_edits ue       ON ue.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
