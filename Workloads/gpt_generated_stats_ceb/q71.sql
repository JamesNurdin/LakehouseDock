-- Top 20 users by reputation with activity metrics
WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS post_score_sum,
        SUM(p.viewcount) AS post_view_sum,
        SUM(p.favoritecount) AS post_favorite_sum,
        COUNT(DISTINCT t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_count,
        SUM(c.score) AS comment_score_sum
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS vote_cast_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cast_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cast_count
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
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
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS edit_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    LEFT JOIN posts p
        ON ph.posthistorytypeid = p.id
    GROUP BY u.id
)
SELECT
    u.id,
    u.reputation,
    COALESCE(up.post_count, 0)          AS post_count,
    COALESCE(up.post_score_sum, 0)      AS post_score_sum,
    COALESCE(up.post_view_sum, 0)       AS post_view_sum,
    COALESCE(up.post_favorite_sum, 0)   AS post_favorite_sum,
    COALESCE(up.tag_count, 0)           AS tag_count,
    COALESCE(uc.comment_count, 0)       AS comment_count,
    COALESCE(uc.comment_score_sum, 0)   AS comment_score_sum,
    COALESCE(uv.vote_cast_count, 0)     AS vote_cast_count,
    COALESCE(uv.upvote_cast_count, 0)   AS upvote_cast_count,
    COALESCE(uv.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(ub.badge_count, 0)         AS badge_count,
    COALESCE(ue.edit_count, 0)          AS edit_count
FROM users u
LEFT JOIN user_posts    up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes    uv ON uv.user_id = u.id
LEFT JOIN user_badges   ub ON ub.user_id = u.id
LEFT JOIN user_edits    ue ON ue.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 20
