WITH
    user_posts AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(score) AS post_score_sum,
            SUM(viewcount) AS post_view_sum,
            SUM(answercount) AS post_answer_sum,
            AVG(score) AS post_score_avg
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments_made AS (
        SELECT
            userid,
            COUNT(*) AS comment_made_count,
            SUM(score) AS comment_made_score_sum
        FROM comments
        GROUP BY userid
    ),
    user_comments_on_posts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS comment_on_post_count,
            SUM(c.score) AS comment_on_post_score_sum
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
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
            p.owneruserid AS userid,
            COUNT(v.id) AS votes_received_count
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_posthistory_edits AS (
        SELECT
            userid,
            COUNT(*) AS posthistory_edit_count
        FROM posthistory
        GROUP BY userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_view_sum, 0) AS post_view_sum,
    COALESCE(up.post_answer_sum, 0) AS post_answer_sum,
    COALESCE(up.post_score_avg, 0) AS post_score_avg,
    COALESCE(ucm.comment_made_count, 0) AS comment_made_count,
    COALESCE(ucm.comment_made_score_sum, 0) AS comment_made_score_sum,
    COALESCE(ucp.comment_on_post_count, 0) AS comment_on_post_count,
    COALESCE(ucp.comment_on_post_score_sum, 0) AS comment_on_post_score_sum,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_edit_count, 0) AS posthistory_edit_count,
    (COALESCE(up.post_count, 0) + COALESCE(ucm.comment_made_count, 0) + COALESCE(uvc.votes_cast_count, 0) + COALESCE(ub.badge_count, 0)) AS total_activity
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments_made ucm ON ucm.userid = u.id
LEFT JOIN user_comments_on_posts ucp ON ucp.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_posthistory_edits uph ON uph.userid = u.id
ORDER BY total_activity DESC
LIMIT 100
