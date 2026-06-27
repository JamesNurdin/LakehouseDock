WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS posts_owned,
        AVG(score) AS avg_post_score,
        SUM(viewcount) AS total_views,
        SUM(answercount) AS total_answers,
        SUM(commentcount) AS total_comments_on_posts,
        SUM(favoritecount) AS total_favorites
    FROM posts
    GROUP BY owneruserid
),
user_edits AS (
    SELECT
        lasteditoruserid AS user_id,
        COUNT(*) AS posts_edited
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
),
user_votes_cast AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS votes_cast,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(v.id) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comments_made,
        AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badges_earned
    FROM badges
    GROUP BY userid
)
SELECT
    u.id,
    u.reputation,
    u.creationdate,
    COALESCE(up.posts_owned, 0) AS posts_owned,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(ue.posts_edited, 0) AS posts_edited,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(uvc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
    COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
    COALESCE(uc.comments_made, 0) AS comments_made,
    COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(ub.badges_earned, 0) AS badges_earned
FROM users u
LEFT JOIN user_posts up ON u.id = up.user_id
LEFT JOIN user_edits ue ON u.id = ue.user_id
LEFT JOIN user_votes_cast uvc ON u.id = uvc.user_id
LEFT JOIN user_votes_received uvr ON u.id = uvr.user_id
LEFT JOIN user_comments uc ON u.id = uc.user_id
LEFT JOIN user_badges ub ON u.id = ub.user_id
ORDER BY u.reputation DESC
LIMIT 100
