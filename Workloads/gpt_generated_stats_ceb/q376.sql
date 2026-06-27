WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_view_count,
        COALESCE(SUM(p.answercount), 0) AS total_answer_count,
        COALESCE(SUM(p.commentcount), 0) AS total_comment_on_posts,
        COALESCE(SUM(p.favoritecount), 0) AS total_favorite_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS edit_count
    FROM users u
    LEFT JOIN posts p ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_made_count,
        COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast_count,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_given
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received_count,
        COALESCE(SUM(v.bountyamount), 0) AS total_bounty_received
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
user_posthistory AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS posthistory_by_user_count
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_posthistory_on_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS posthistory_on_user_posts_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN posthistory ph ON ph.posthistorytypeid = p.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS user_id,
        COUNT(t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT
    u.id AS user_id,
    u.reputation,
    up.post_count,
    up.total_post_score,
    up.total_view_count,
    up.total_answer_count,
    up.total_comment_on_posts,
    up.total_favorite_count,
    ue.edit_count,
    uc.comment_made_count,
    uc.total_comment_score,
    uv_cast.votes_cast_count,
    uv_cast.total_bounty_given,
    uv_received.votes_received_count,
    uv_received.total_bounty_received,
    ub.badge_count,
    uph.posthistory_by_user_count,
    uph_posts.posthistory_on_user_posts_count,
    ut.tag_count,
    -- Derived engagement metrics
    COALESCE(up.total_post_score, 0) / NULLIF(up.post_count, 0) AS avg_post_score,
    COALESCE(uc.total_comment_score, 0) / NULLIF(uc.comment_made_count, 0) AS avg_comment_score,
    (COALESCE(up.post_count, 0) + COALESCE(uc.comment_made_count, 0) + COALESCE(uv_cast.votes_cast_count, 0) + COALESCE(ub.badge_count, 0)) AS total_activity_score
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_edits ue ON ue.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uv_cast ON uv_cast.user_id = u.id
LEFT JOIN user_votes_received uv_received ON uv_received.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_posthistory_on_posts uph_posts ON uph_posts.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY total_activity_score DESC, u.reputation DESC
LIMIT 100
