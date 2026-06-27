/*
  Analytical query: user‑level activity summary across posts, tags, comments, votes, badges, edits and post‑history.
  All joins respect the allowed join rules and only columns defined in the DDL are used.
*/
WITH user_posts AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(score) AS post_score_sum,
        AVG(score) AS post_score_avg,
        SUM(viewcount) AS post_viewcount_sum,
        SUM(answercount) AS post_answercount_sum
    FROM posts
    GROUP BY owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT t.id) AS tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_edits AS (
    SELECT
        lasteditoruserid AS userid,
        COUNT(*) AS edit_count
    FROM posts
    GROUP BY lasteditoruserid
),
user_comments AS (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid,
        COUNT(*) AS vote_count,
        COUNT(DISTINCT postid) AS distinct_posts_voted
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT
        userid,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.post_count, 0)               AS post_count,
    COALESCE(p.post_score_sum, 0)           AS post_score_sum,
    COALESCE(p.post_score_avg, 0)           AS post_score_avg,
    COALESCE(p.post_viewcount_sum, 0)       AS post_viewcount_sum,
    COALESCE(p.post_answercount_sum, 0)     AS post_answercount_sum,
    COALESCE(t.tag_count, 0)                AS tag_count,
    COALESCE(e.edit_count, 0)               AS edit_count,
    COALESCE(c.comment_count, 0)            AS comment_count,
    COALESCE(c.comment_score_sum, 0)        AS comment_score_sum,
    COALESCE(v.vote_count, 0)               AS vote_count,
    COALESCE(v.distinct_posts_voted, 0)     AS distinct_posts_voted,
    COALESCE(b.badge_count, 0)              AS badge_count,
    COALESCE(h.posthistory_count, 0)        AS posthistory_count
FROM users u
LEFT JOIN user_posts p          ON p.userid = u.id
LEFT JOIN user_tags t           ON t.userid = u.id
LEFT JOIN user_edits e          ON e.userid = u.id
LEFT JOIN user_comments c       ON c.userid = u.id
LEFT JOIN user_votes v          ON v.userid = u.id
LEFT JOIN user_badges b         ON b.userid = u.id
LEFT JOIN user_posthistory h    ON h.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
