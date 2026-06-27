WITH user_posts AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS authored_posts,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(AVG(p.score), 0) AS avg_post_score
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    GROUP BY u.id
),
user_comments AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comments_made,
        COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM users u
    LEFT JOIN comments c
        ON c.userid = u.id
    GROUP BY u.id
),
user_votes AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_cast
    FROM users u
    LEFT JOIN votes v
        ON v.userid = u.id
    GROUP BY u.id
),
user_badges AS (
    SELECT
        u.id AS user_id,
        COUNT(b.id) AS badges_earned
    FROM users u
    LEFT JOIN badges b
        ON b.userid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS post_edits_made
    FROM users u
    LEFT JOIN posthistory ph
        ON ph.userid = u.id
    GROUP BY u.id
),
user_links AS (
    SELECT
        u.id AS user_id,
        COUNT(pl.id) AS post_links_created
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN postlinks pl
        ON pl.postid = p.id
    GROUP BY u.id
),
user_votes_received AS (
    SELECT
        u.id AS user_id,
        COUNT(v.id) AS votes_received
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN votes v
        ON v.postid = p.id
    GROUP BY u.id
),
user_comments_received AS (
    SELECT
        u.id AS user_id,
        COUNT(c.id) AS comments_received
    FROM users u
    LEFT JOIN posts p
        ON p.owneruserid = u.id
    LEFT JOIN comments c
        ON c.postid = p.id
    GROUP BY u.id
),
user_summary AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate AS user_creationdate,
        COALESCE(up.authored_posts, 0) AS authored_posts,
        COALESCE(up.total_post_score, 0) AS total_post_score,
        COALESCE(up.avg_post_score, 0) AS avg_post_score,
        COALESCE(uc.comments_made, 0) AS comments_made,
        COALESCE(uc.total_comment_score, 0) AS total_comment_score,
        COALESCE(uv.votes_cast, 0) AS votes_cast,
        COALESCE(ub.badges_earned, 0) AS badges_earned,
        COALESCE(ue.post_edits_made, 0) AS post_edits_made,
        COALESCE(ul.post_links_created, 0) AS post_links_created,
        COALESCE(uvr.votes_received, 0) AS votes_received,
        COALESCE(ucr.comments_received, 0) AS comments_received
    FROM users u
    LEFT JOIN user_posts up               ON up.user_id = u.id
    LEFT JOIN user_comments uc           ON uc.user_id = u.id
    LEFT JOIN user_votes uv              ON uv.user_id = u.id
    LEFT JOIN user_badges ub             ON ub.user_id = u.id
    LEFT JOIN user_edits ue              ON ue.user_id = u.id
    LEFT JOIN user_links ul              ON ul.user_id = u.id
    LEFT JOIN user_votes_received uvr   ON uvr.user_id = u.id
    LEFT JOIN user_comments_received ucr ON ucr.user_id = u.id
)
SELECT *
FROM user_summary
ORDER BY total_post_score DESC
LIMIT 20
