WITH user_posts AS (
    SELECT
        u.id AS userid,
        COUNT(p.id) AS posts_owned,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_views,
        COALESCE(SUM(p.answercount), 0) AS total_answers,
        COALESCE(SUM(p.commentcount), 0) AS total_comments_received,
        COALESCE(SUM(p.favoritecount), 0) AS total_favorites
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS userid,
        COUNT(v.id) AS votes_received,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_received,
        COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_received
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN votes v ON v.postid = p.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS userid,
        COUNT(b.id) AS badges_earned
    FROM users u
    LEFT JOIN badges b ON b.userid = u.id
    GROUP BY u.id
),
user_comments_made AS (
    SELECT
        u.id AS userid,
        COUNT(c.id) AS comments_made
    FROM users u
    LEFT JOIN comments c ON c.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS userid,
        COUNT(ph.id) AS edits_made
    FROM users u
    LEFT JOIN posthistory ph ON ph.userid = u.id
    GROUP BY u.id
),
user_links_created AS (
    SELECT
        u.id AS userid,
        COUNT(pl.id) AS links_created
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN postlinks pl ON pl.postid = p.id
    GROUP BY u.id
),
user_tags AS (
    SELECT
        u.id AS userid,
        COUNT(t.id) AS tags_associated
    FROM users u
    LEFT JOIN posts p ON p.owneruserid = u.id
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY u.id
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.posts_owned, 0) AS posts_owned,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_comments_received, 0) AS total_comments_received,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
    COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
    COALESCE(ub.badges_earned, 0) AS badges_earned,
    COALESCE(ucm.comments_made, 0) AS comments_made,
    COALESCE(ue.edits_made, 0) AS edits_made,
    COALESCE(ulc.links_created, 0) AS links_created,
    COALESCE(ut.tags_associated, 0) AS tags_associated
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_comments_made ucm ON ucm.userid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
LEFT JOIN user_links_created ulc ON ulc.userid = u.id
LEFT JOIN user_tags ut ON ut.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
