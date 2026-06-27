WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS total_posts,
        SUM(CASE WHEN p.posttypeid = 1 THEN 1 ELSE 0 END) AS total_questions,
        SUM(CASE WHEN p.posttypeid = 2 THEN 1 ELSE 0 END) AS total_answers,
        SUM(p.score) AS total_post_score,
        SUM(p.viewcount) AS total_views,
        SUM(p.favoritecount) AS total_favorites
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS total_comments,
        SUM(c.score) AS total_comment_score
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS total_badges
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_votes_cast AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast,
        SUM(CASE WHEN v.bountyamount IS NOT NULL THEN v.bountyamount ELSE 0 END) AS total_bounty_given
    FROM users u
    LEFT JOIN votes v ON v.userid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
)
SELECT
    u.id,
    u.reputation,
    COALESCE(up.total_posts, 0) AS total_posts,
    COALESCE(up.total_questions, 0) AS total_questions,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(uc.total_comments, 0) AS total_comments,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(ub.total_badges, 0) AS total_badges,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
    COALESCE(uvr.downvotes_received, 0) AS downvotes_received
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
ORDER BY total_posts DESC
LIMIT 100
