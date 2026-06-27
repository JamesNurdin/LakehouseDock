WITH user_posts AS (
    SELECT
        owneruserid,
        COUNT(*) AS post_count,
        SUM(score) AS total_post_score,
        AVG(score) AS avg_post_score,
        SUM(viewcount) AS total_view_count,
        SUM(answercount) AS total_answer_count,
        SUM(commentcount) AS total_comment_on_posts,
        SUM(favoritecount) AS total_favorite_count
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid,
        COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT
        userid,
        COUNT(*) AS votes_cast_count
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT
        p.owneruserid,
        COUNT(*) AS votes_received_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_edits AS (
    SELECT
        userid,
        COUNT(*) AS edit_count
    FROM posthistory
    GROUP BY userid
),
user_links_created AS (
    SELECT
        p.owneruserid,
        COUNT(*) AS link_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_view_count, 0) AS total_view_count,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_on_posts, 0) AS total_comment_on_posts,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(ul.link_count, 0) AS link_count
FROM users u
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.owneruserid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
LEFT JOIN user_links_created ul ON ul.owneruserid = u.id
ORDER BY total_post_score DESC
LIMIT 100
