WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        AVG(p.answercount) AS avg_answer_count,
        COALESCE(SUM(p.commentcount), 0) AS total_comment_count_on_posts,
        COALESCE(SUM(p.favoritecount), 0) AS total_favorite_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments_made AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_made_count
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_comments_on_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comment_received_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN comments c ON c.postid = p.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS user_id,
        COALESCE(SUM(t.count), 0) AS total_tag_count,
        COUNT(t.id) AS tag_count
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT
    u.id AS user_id,
    u.reputation,
    up.post_count,
    up.total_post_score,
    up.avg_answer_count,
    up.total_comment_count_on_posts,
    up.total_favorite_count,
    cm.comment_made_count,
    cr.comment_received_count,
    vr.votes_received_count,
    vr.upvotes_received,
    vr.downvotes_received,
    vc.votes_cast_count,
    vc.upvotes_cast,
    vc.downvotes_cast,
    ub.badge_count,
    ut.total_tag_count,
    ut.tag_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments_made cm ON cm.user_id = u.id
LEFT JOIN user_comments_on_posts cr ON cr.user_id = u.id
LEFT JOIN user_votes_received vr ON vr.user_id = u.id
LEFT JOIN user_votes_cast vc ON vc.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
