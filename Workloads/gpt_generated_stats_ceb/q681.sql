/*
  Analytical query that aggregates a variety of activity metrics for each Stack Exchange user.
  It combines information from posts, comments, votes, badges, post‑history edits, tags and post‑links.
  All joins follow the allowed join rules and no date literals are used.
*/
WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_views,
        COALESCE(AVG(p.answercount), 0) AS avg_answer_count,
        COALESCE(AVG(p.commentcount), 0) AS avg_comment_count,
        COALESCE(SUM(p.favoritecount), 0) AS total_favorite_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_made_count,
        COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_cast_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_cast_count
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_received_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_received_count
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
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS edit_count
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT t.id) AS distinct_tags_used
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_links AS (
    SELECT
        u.id AS user_id,
        COUNT(DISTINCT pl.id) AS post_links_count
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.postid = p.id OR pl.relatedpostid = p.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.post_count,
    up.total_post_score,
    up.total_views,
    up.avg_answer_count,
    up.avg_comment_count,
    up.total_favorite_count,
    uc.comment_made_count,
    uc.total_comment_score,
    uv_cast.votes_cast_count,
    uv_cast.upvote_cast_count,
    uv_cast.downvote_cast_count,
    uv_recv.votes_received_count,
    uv_recv.upvote_received_count,
    uv_recv.downvote_received_count,
    ub.badge_count,
    ue.edit_count,
    ut.distinct_tags_used,
    ul.post_links_count
FROM user_posts up
LEFT JOIN user_comments uc
    ON uc.user_id = up.user_id
LEFT JOIN user_votes_cast uv_cast
    ON uv_cast.user_id = up.user_id
LEFT JOIN user_votes_received uv_recv
    ON uv_recv.user_id = up.user_id
LEFT JOIN user_badges ub
    ON ub.user_id = up.user_id
LEFT JOIN user_edits ue
    ON ue.user_id = up.user_id
LEFT JOIN user_tags ut
    ON ut.user_id = up.user_id
LEFT JOIN user_links ul
    ON ul.user_id = up.user_id
ORDER BY up.total_post_score DESC
LIMIT 100
