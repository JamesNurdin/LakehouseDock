WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS posts_owned,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_viewcount,
        COALESCE(SUM(p.favoritecount), 0) AS total_favoritecount
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS posts_edited,
        COALESCE(SUM(p.score), 0) AS total_edited_post_score
    FROM users u
    LEFT JOIN posts p ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comments_made,
        COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_cast,
        COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badges_earned
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_posthistory AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS posthistory_events
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_postlinks AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS postlinks_owned
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS user_id,
        COUNT(t.id) AS tags_owned
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.posts_owned,
    up.total_post_score,
    up.total_viewcount,
    up.total_favoritecount,
    ue.posts_edited,
    ue.total_edited_post_score,
    uc.comments_made,
    uc.total_comment_score,
    uv.votes_cast,
    uv.upvotes_cast,
    uv.downvotes_cast,
    ub.badges_earned,
    uph.posthistory_events,
    upl.postlinks_owned,
    ut.tags_owned,
    (up.posts_owned * 2 + uc.comments_made + uv.votes_cast + ub.badges_earned) AS engagement_score
FROM user_posts up
LEFT JOIN user_edits ue ON ue.user_id = up.user_id
LEFT JOIN user_comments uc ON uc.user_id = up.user_id
LEFT JOIN user_votes_cast uv ON uv.user_id = up.user_id
LEFT JOIN user_badges ub ON ub.user_id = up.user_id
LEFT JOIN user_posthistory uph ON uph.user_id = up.user_id
LEFT JOIN user_postlinks upl ON upl.user_id = up.user_id
LEFT JOIN user_tags ut ON ut.user_id = up.user_id
ORDER BY engagement_score DESC, up.posts_owned DESC
LIMIT 100
