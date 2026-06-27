/*
   Analytical query: per‑user activity summary across posts, comments, votes, badges, post links, tags, and post‑history events.
   Uses only the allowed tables and join rules, aggregates in CTEs to avoid duplication, and orders by user reputation.
*/
WITH user_posts AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(score) AS total_post_score,
        AVG(score) AS avg_post_score,
        SUM(viewcount) AS total_viewcount,
        SUM(answercount) AS total_answercount,
        SUM(commentcount) AS total_commentcount,
        SUM(favoritecount) AS total_favoritecount
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        SUM(score) AS total_comment_score,
        AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(bountyamount) AS total_bounty_amount
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
user_post_links AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_link_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_posthistory AS (
    SELECT
        userid,
        COUNT(*) AS post_history_count
    FROM posthistory
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creationdate,
    u.views AS user_views,
    u.upvotes AS user_upvotes,
    u.downvotes AS user_downvotes,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    COALESCE(p.total_answercount, 0) AS total_answercount,
    COALESCE(p.total_commentcount, 0) AS total_commentcount,
    COALESCE(p.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(c.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.upvote_count, 0) AS upvote_count,
    COALESCE(v.downvote_count, 0) AS downvote_count,
    COALESCE(v.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(pl.post_link_count, 0) AS post_link_count,
    COALESCE(tg.tag_count, 0) AS tag_count,
    COALESCE(ph.post_history_count, 0) AS post_history_count
FROM users u
LEFT JOIN user_posts p   ON p.userid = u.id
LEFT JOIN user_comments c ON c.userid = u.id
LEFT JOIN user_votes v    ON v.userid = u.id
LEFT JOIN user_badges b   ON b.userid = u.id
LEFT JOIN user_post_links pl ON pl.userid = u.id
LEFT JOIN user_tags tg    ON tg.userid = u.id
LEFT JOIN user_posthistory ph ON ph.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
