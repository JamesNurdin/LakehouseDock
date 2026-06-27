WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_score,
        AVG(p.score) AS avg_score,
        SUM(p.viewcount) AS total_views,
        SUM(p.answercount) AS total_answers,
        SUM(p.commentcount) AS total_comments_on_posts
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count
    FROM comments c
    GROUP BY c.userid
),
user_votes_cast AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cast,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cast
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_score, 0) AS total_post_score,
    COALESCE(up.avg_score, 0) AS avg_post_score,
    COALESCE(up.total_views, 0) AS total_post_views,
    COALESCE(up.total_answers, 0) AS total_answers_on_posts,
    COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.upvote_cast, 0) AS upvotes_cast,
    COALESCE(uvc.downvote_cast, 0) AS downvotes_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
    COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ut.tag_count, 0) AS distinct_tag_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
