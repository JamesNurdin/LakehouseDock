WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_views,
        COALESCE(SUM(p.favoritecount), 0) AS total_favorites
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
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
user_votes_made AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_made,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_made,
        COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_made
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_received,
        COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_received,
        COALESCE(COUNT(v.id), 0) AS votes_received
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
),
user_edit_history AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS edit_count,
        COUNT(CASE WHEN p.owneruserid = u.id THEN 1 END) AS edit_on_own_posts
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    LEFT JOIN posts p
        ON ph.posthistorytypeid = p.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.post_count,
    up.total_post_score,
    up.total_views,
    up.total_favorites,
    uc.comment_count,
    uc.total_comment_score,
    um.votes_made,
    um.upvotes_made,
    um.downvotes_made,
    ur.upvotes_received,
    ur.downvotes_received,
    ur.votes_received,
    ub.badge_count,
    ue.edit_count,
    ue.edit_on_own_posts,
    CASE WHEN up.post_count > 0 THEN up.total_post_score * 1.0 / up.post_count ELSE NULL END AS avg_post_score,
    CASE WHEN up.post_count > 0 THEN up.total_views * 1.0 / up.post_count ELSE NULL END AS avg_views_per_post
FROM user_posts up
LEFT JOIN user_comments uc
    ON uc.user_id = up.user_id
LEFT JOIN user_votes_made um
    ON um.user_id = up.user_id
LEFT JOIN user_votes_received ur
    ON ur.user_id = up.user_id
LEFT JOIN user_badges ub
    ON ub.user_id = up.user_id
LEFT JOIN user_edit_history ue
    ON ue.user_id = up.user_id
ORDER BY up.reputation DESC
LIMIT 100
