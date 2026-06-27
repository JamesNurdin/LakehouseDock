WITH post_comments AS (
    SELECT
        p.id AS post_id,
        p.owneruserid,
        p.score AS post_score,
        p.viewcount,
        COUNT(c.id) AS comment_count
    FROM posts p
    LEFT JOIN comments c ON c.postid = p.id
    GROUP BY p.id, p.owneruserid, p.score, p.viewcount
),
post_votes AS (
    SELECT
        p.id AS post_id,
        COUNT(v.id) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
    FROM posts p
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY p.id
),
post_metrics AS (
    SELECT
        pc.post_id,
        pc.owneruserid,
        pc.post_score,
        pc.viewcount,
        pc.comment_count,
        COALESCE(pv.vote_count, 0) AS vote_count,
        COALESCE(pv.upvote_count, 0) AS upvote_count,
        COALESCE(pv.downvote_count, 0) AS downvote_count
    FROM post_comments pc
    LEFT JOIN post_votes pv ON pv.post_id = pc.post_id
),
user_badges AS (
    SELECT
        b.userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COUNT(DISTINCT pm.post_id) AS total_posts,
    COALESCE(SUM(pm.post_score), 0) AS total_post_score,
    COALESCE(AVG(pm.post_score), 0) AS avg_post_score,
    COALESCE(SUM(pm.viewcount), 0) AS total_view_count,
    COALESCE(AVG(pm.viewcount), 0) AS avg_view_count,
    COALESCE(SUM(pm.comment_count), 0) AS total_comments_on_posts,
    COALESCE(SUM(pm.vote_count), 0) AS total_votes_on_posts,
    COALESCE(SUM(pm.upvote_count), 0) AS total_upvotes_on_posts,
    COALESCE(SUM(pm.downvote_count), 0) AS total_downvotes_on_posts,
    COALESCE(MAX(b.badge_count), 0) AS badge_count
FROM users u
LEFT JOIN post_metrics pm ON pm.owneruserid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
GROUP BY u.id, u.reputation, u.creationdate
ORDER BY total_posts DESC
LIMIT 100
