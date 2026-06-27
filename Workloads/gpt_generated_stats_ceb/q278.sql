WITH user_posts AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(score) AS total_post_score,
        SUM(viewcount) AS total_viewcount,
        SUM(answercount) AS total_answer_count,
        SUM(commentcount) AS total_comment_count,
        SUM(favoritecount) AS total_favorite_count
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        SUM(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT
        userid,
        COUNT(*) AS votes_cast,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
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
        COUNT(*) AS posthistory_events
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
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    COALESCE(p.total_answer_count, 0) AS total_answer_count,
    COALESCE(p.total_comment_count, 0) AS total_comment_count,
    COALESCE(p.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.posthistory_events, 0) AS posthistory_events,
    CASE WHEN COALESCE(p.post_count, 0) > 0 THEN CAST(COALESCE(p.total_post_score, 0) AS double) / p.post_count ELSE NULL END AS avg_post_score
FROM users u
LEFT JOIN user_posts p ON u.id = p.userid
LEFT JOIN user_comments c ON u.id = c.userid
LEFT JOIN user_votes_cast vc ON u.id = vc.userid
LEFT JOIN user_votes_received vr ON u.id = vr.userid
LEFT JOIN user_badges b ON u.id = b.userid
LEFT JOIN user_posthistory ph ON u.id = ph.userid
ORDER BY total_post_score DESC
LIMIT 100
