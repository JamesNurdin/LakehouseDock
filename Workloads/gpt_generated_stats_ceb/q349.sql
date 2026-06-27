-- User activity summary across posts, comments, votes, and badges
WITH
    user_info AS (
        SELECT id, reputation
        FROM users
    ),
    user_posts AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS total_posts,
            SUM(score) AS total_post_score,
            AVG(score) AS avg_post_score,
            SUM(viewcount) AS total_viewcount,
            SUM(answercount) AS total_answercount,
            SUM(favoritecount) AS total_favoritecount
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments_by_user AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_comments_made,
            SUM(score) AS total_comment_score_made,
            AVG(score) AS avg_comment_score_made
        FROM comments
        GROUP BY userid
    ),
    user_comments_on_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(c.id) AS total_comments_received,
            SUM(c.score) AS total_comment_score_received
        FROM posts p
        JOIN comments c ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_votes_cast AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_votes_cast,
            SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_cast,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_cast
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(v.id) AS total_votes_received,
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
        FROM posts p
        JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS total_badges
        FROM badges
        GROUP BY userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_answercount, 0) AS total_answercount,
    COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(ucbm.total_comments_made, 0) AS total_comments_made,
    COALESCE(ucbm.total_comment_score_made, 0) AS total_comment_score_made,
    COALESCE(ucbm.avg_comment_score_made, 0) AS avg_comment_score_made,
    COALESCE(ucpr.total_comments_received, 0) AS total_comments_received,
    COALESCE(ucpr.total_comment_score_received, 0) AS total_comment_score_received,
    COALESCE(vc.total_votes_cast, 0) AS total_votes_cast,
    COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(vr.total_votes_received, 0) AS total_votes_received,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(b.total_badges, 0) AS total_badges
FROM user_info u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments_by_user ucbm ON ucbm.user_id = u.id
LEFT JOIN user_comments_on_posts ucpr ON ucpr.user_id = u.id
LEFT JOIN user_votes_cast vc ON vc.user_id = u.id
LEFT JOIN user_votes_received vr ON vr.user_id = u.id
LEFT JOIN user_badges b ON b.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 100
