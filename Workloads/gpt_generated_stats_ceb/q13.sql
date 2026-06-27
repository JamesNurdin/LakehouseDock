-- Analytical overview of user activity across the Stack Exchange data set
-- This query aggregates posts, comments, votes, badges, edits, and tag usage per user.
WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS post_score_sum,
        COALESCE(SUM(p.viewcount), 0) AS post_view_sum
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
user_votes AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS vote_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvote_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvote_count
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
        COUNT(p.id) AS edited_post_count,
        COALESCE(SUM(p.score), 0) AS edited_post_score_sum
    FROM users u
    LEFT JOIN posts p
        ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_tag_counts AS (
    SELECT
        u.id AS user_id,
        COALESCE(SUM(t.count), 0) AS total_tag_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT
    u.id,
    u.reputation,
    up.post_count,
    up.post_score_sum,
    uc.comment_count,
    uc.comment_score_sum,
    uv.vote_count,
    uv.upvote_count,
    uv.downvote_count,
    ub.badge_count,
    ue.edited_post_count,
    ue.edited_post_score_sum,
    ut.total_tag_count
FROM users u
LEFT JOIN user_posts up      ON up.user_id = u.id
LEFT JOIN user_comments uc   ON uc.user_id = u.id
LEFT JOIN user_votes uv      ON uv.user_id = u.id
LEFT JOIN user_badges ub     ON ub.user_id = u.id
LEFT JOIN user_edits ue      ON ue.user_id = u.id
LEFT JOIN user_tag_counts ut ON ut.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
