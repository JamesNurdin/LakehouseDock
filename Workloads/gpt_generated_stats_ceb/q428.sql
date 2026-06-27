WITH
    users_base AS (
        SELECT
            id AS user_id,
            reputation
        FROM users
    ),
    posts_metrics AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS posts_owned,
            COALESCE(SUM(score), 0) AS total_post_score,
            COALESCE(AVG(score), 0) AS avg_post_score
        FROM posts
        GROUP BY owneruserid
    ),
    comments_metrics AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comments_made,
            COALESCE(SUM(score), 0) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    badges_metrics AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badges_earned
        FROM badges
        GROUP BY userid
    ),
    votes_cast_metrics AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS votes_cast
        FROM votes
        GROUP BY userid
    ),
    votes_received_metrics AS (
        SELECT
            p.owneruserid AS user_id,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    tags_authored_metrics AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS tags_authored
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    ub.user_id,
    ub.reputation,
    COALESCE(pm.posts_owned, 0) AS posts_owned,
    COALESCE(pm.total_post_score, 0) AS total_post_score,
    COALESCE(pm.avg_post_score, 0) AS avg_post_score,
    COALESCE(cm.comments_made, 0) AS comments_made,
    COALESCE(cm.total_comment_score, 0) AS total_comment_score,
    COALESCE(bm.badges_earned, 0) AS badges_earned,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(ta.tags_authored, 0) AS tags_authored
FROM users_base ub
LEFT JOIN posts_metrics pm ON pm.user_id = ub.user_id
LEFT JOIN comments_metrics cm ON cm.user_id = ub.user_id
LEFT JOIN badges_metrics bm ON bm.user_id = ub.user_id
LEFT JOIN votes_cast_metrics vc ON vc.user_id = ub.user_id
LEFT JOIN votes_received_metrics vr ON vr.user_id = ub.user_id
LEFT JOIN tags_authored_metrics ta ON ta.user_id = ub.user_id
ORDER BY total_post_score DESC
LIMIT 100
