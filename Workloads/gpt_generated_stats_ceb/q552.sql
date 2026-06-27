WITH user_badges AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id, u.reputation
),
user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS post_count,
        COUNT(CASE WHEN p.posttypeid = 2 THEN 1 END) AS answer_count,
        AVG(p.score) AS avg_post_score,
        SUM(p.score) AS total_post_score,
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
        AVG(c.score) AS avg_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast,
        COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvote_cast,
        COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvote_cast,
        SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_given
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received,
        COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvote_received,
        COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvote_received,
        SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
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
user_tag_excerpts AS (
    SELECT
        u.id AS user_id,
        COUNT(t.id) AS tag_excerpt_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_postlinks AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS postlink_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY u.id
)
SELECT
    ub.user_id,
    ub.reputation,
    ub.badge_count,
    up.post_count,
    up.answer_count,
    up.avg_post_score,
    uc.comment_count,
    uc.avg_comment_score,
    uv_cast.votes_cast,
    uv_cast.upvote_cast,
    uv_cast.downvote_cast,
    uv_received.votes_received,
    uv_received.upvote_received,
    uv_received.downvote_received,
    ue.edit_count,
    ut.tag_excerpt_count,
    upl.postlink_count
FROM user_badges ub
LEFT JOIN user_posts up ON up.user_id = ub.user_id
LEFT JOIN user_comments uc ON uc.user_id = ub.user_id
LEFT JOIN user_votes_cast uv_cast ON uv_cast.user_id = ub.user_id
LEFT JOIN user_votes_received uv_received ON uv_received.user_id = ub.user_id
LEFT JOIN user_edits ue ON ue.user_id = ub.user_id
LEFT JOIN user_tag_excerpts ut ON ut.user_id = ub.user_id
LEFT JOIN user_postlinks upl ON upl.user_id = ub.user_id
ORDER BY ub.reputation DESC
LIMIT 100
