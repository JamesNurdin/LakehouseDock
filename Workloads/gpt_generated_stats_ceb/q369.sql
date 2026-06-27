WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        COALESCE(SUM(score), 0) AS total_post_score,
        COALESCE(SUM(viewcount), 0) AS total_post_views
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count,
        COALESCE(SUM(score), 0) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_edits AS (
    SELECT
        lasteditoruserid AS user_id,
        COUNT(*) AS edit_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
),
user_posthistory AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_post_views, 0) AS total_post_views,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.upvote_count, 0) AS upvote_count,
    COALESCE(v.downvote_count, 0) AS downvote_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN user_posts p        ON p.user_id = u.id
LEFT JOIN user_comments c     ON c.user_id = u.id
LEFT JOIN user_votes v        ON v.user_id = u.id
LEFT JOIN user_badges b       ON b.user_id = u.id
LEFT JOIN user_edits e        ON e.user_id = u.id
LEFT JOIN user_posthistory ph ON ph.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
