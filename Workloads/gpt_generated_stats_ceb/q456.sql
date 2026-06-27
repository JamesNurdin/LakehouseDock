-- User activity summary: reputation, posts, comments, votes, badges, edits, tags created, and post links per user
WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS total_posts,
        SUM(CASE WHEN p.posttypeid = 1 THEN 1 ELSE 0 END) AS total_questions,
        SUM(CASE WHEN p.posttypeid = 2 THEN 1 ELSE 0 END) AS total_answers,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_views
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS total_comments,
        AVG(c.score) AS avg_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS total_votes,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_given,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_given
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS total_badges
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS total_edits
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS user_id,
        COUNT(t.id) AS tags_created
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
),
user_postlinks AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS post_links_created
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY u.id
)
SELECT
    up.user_id,
    up.reputation,
    up.total_posts,
    up.total_questions,
    up.total_answers,
    up.avg_post_score,
    up.total_views,
    uc.total_comments,
    uc.avg_comment_score,
    uv.total_votes,
    uv.upvotes_given,
    uv.downvotes_given,
    ub.total_badges,
    ue.total_edits,
    ut.tags_created,
    upl.post_links_created
FROM user_posts up
LEFT JOIN user_comments uc ON uc.user_id = up.user_id
LEFT JOIN user_votes uv ON uv.user_id = up.user_id
LEFT JOIN user_badges ub ON ub.user_id = up.user_id
LEFT JOIN user_edits ue ON ue.user_id = up.user_id
LEFT JOIN user_tags ut ON ut.user_id = up.user_id
LEFT JOIN user_postlinks upl ON upl.user_id = up.user_id
ORDER BY up.reputation DESC
LIMIT 100
