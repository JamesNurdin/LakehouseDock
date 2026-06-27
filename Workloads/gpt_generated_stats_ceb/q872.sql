WITH
    user_posts AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            AVG(score) AS avg_post_score,
            SUM(answercount) AS total_answers,
            SUM(commentcount) AS total_comments_on_posts
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments_made AS (
        SELECT
            userid,
            COUNT(*) AS comment_made_count
        FROM comments
        GROUP BY userid
    ),
    user_comments_received AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(c.id) AS comment_received_count
        FROM posts p
        LEFT JOIN comments c ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_votes_cast AS (
        SELECT
            userid,
            COUNT(*) AS votes_cast
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(v.id) AS votes_received
        FROM posts p
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_edits AS (
        SELECT
            lasteditoruserid AS userid,
            COUNT(*) AS edit_count
        FROM posts
        GROUP BY lasteditoruserid
    ),
    user_history AS (
        SELECT
            userid,
            COUNT(*) AS history_actions
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
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_answers, 0) AS total_answers,
    COALESCE(p.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(cm.comment_made_count, 0) AS comment_made_count,
    COALESCE(cr.comment_received_count, 0) AS comment_received_count,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(h.history_actions, 0) AS history_actions,
    (
        COALESCE(p.post_count, 0) * 2
        + COALESCE(cm.comment_made_count, 0)
        + COALESCE(b.badge_count, 0)
        + COALESCE(vc.votes_cast, 0)
    ) AS activity_score
FROM users u
LEFT JOIN user_posts p ON u.id = p.userid
LEFT JOIN user_comments_made cm ON u.id = cm.userid
LEFT JOIN user_comments_received cr ON u.id = cr.userid
LEFT JOIN user_votes_cast vc ON u.id = vc.userid
LEFT JOIN user_votes_received vr ON u.id = vr.userid
LEFT JOIN user_badges b ON u.id = b.userid
LEFT JOIN user_edits e ON u.id = e.userid
LEFT JOIN user_history h ON u.id = h.userid
ORDER BY u.reputation DESC, activity_score DESC
LIMIT 100
