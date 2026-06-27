WITH
    user_posts AS (
        SELECT
            posts.owneruserid AS user_id,
            COUNT(posts.id) AS post_count,
            SUM(posts.score) AS total_post_score,
            AVG(posts.score) AS avg_post_score
        FROM posts
        GROUP BY posts.owneruserid
    ),
    user_comments_written AS (
        SELECT
            comments.userid AS user_id,
            COUNT(comments.id) AS comments_written
        FROM comments
        GROUP BY comments.userid
    ),
    user_comments_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(c.id) AS comments_received
        FROM posts p
        LEFT JOIN comments c ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(v.id) AS votes_received
        FROM posts p
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_votes_cast AS (
        SELECT
            votes.userid AS user_id,
            COUNT(votes.id) AS votes_cast
        FROM votes
        GROUP BY votes.userid
    ),
    user_badges AS (
        SELECT
            badges.userid AS user_id,
            COUNT(badges.id) AS badge_count
        FROM badges
        GROUP BY badges.userid
    ),
    user_post_edits AS (
        SELECT
            posthistory.userid AS user_id,
            COUNT(posthistory.id) AS post_edits
        FROM posthistory
        GROUP BY posthistory.userid
    ),
    user_info AS (
        SELECT
            users.id,
            users.reputation,
            users.creationdate
        FROM users
    )
SELECT
    ui.id,
    ui.reputation,
    ui.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(ucw.comments_written, 0) AS comments_written,
    COALESCE(ucr.comments_received, 0) AS comments_received,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.post_edits, 0) AS post_edits
FROM user_info ui
LEFT JOIN user_posts up ON up.user_id = ui.id
LEFT JOIN user_comments_written ucw ON ucw.user_id = ui.id
LEFT JOIN user_comments_received ucr ON ucr.user_id = ui.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = ui.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = ui.id
LEFT JOIN user_badges ub ON ub.user_id = ui.id
LEFT JOIN user_post_edits ue ON ue.user_id = ui.id
ORDER BY ui.reputation DESC
LIMIT 100
