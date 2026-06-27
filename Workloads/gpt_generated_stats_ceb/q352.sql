WITH
    user_info AS (
        SELECT
            id,
            reputation,
            creationdate
        FROM users
    ),
    user_badges AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_posts AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            SUM(viewcount) AS total_viewcount,
            AVG(score) AS avg_post_score,
            AVG(viewcount) AS avg_viewcount
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments_made AS (
        SELECT
            userid,
            COUNT(*) AS comment_made_count,
            SUM(score) AS total_comment_made_score
        FROM comments
        GROUP BY userid
    ),
    user_comments_received AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS comment_received_count,
            SUM(c.score) AS total_comment_received_score
        FROM comments c
        JOIN posts p
            ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS votes_received_count,
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
        FROM votes v
        JOIN posts p
            ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_votes_cast AS (
        SELECT
            userid,
            COUNT(*) AS votes_cast_count
        FROM votes
        GROUP BY userid
    ),
    user_tags_used AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(DISTINCT t.id) AS distinct_tags_used
        FROM tags t
        JOIN posts p
            ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_posthistory AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS posthistory_count
        FROM posthistory ph
        JOIN posts p
            ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p
            ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.avg_viewcount, 0) AS avg_viewcount,
    COALESCE(cm.comment_made_count, 0) AS comment_made_count,
    COALESCE(cm.total_comment_made_score, 0) AS total_comment_made_score,
    COALESCE(cr.comment_received_count, 0) AS comment_received_count,
    COALESCE(cr.total_comment_received_score, 0) AS total_comment_received_score,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(tg.distinct_tags_used, 0) AS distinct_tags_used,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(pl.postlink_count, 0) AS postlink_count
FROM user_info u
LEFT JOIN user_badges b
    ON b.userid = u.id
LEFT JOIN user_posts p
    ON p.userid = u.id
LEFT JOIN user_comments_made cm
    ON cm.userid = u.id
LEFT JOIN user_comments_received cr
    ON cr.userid = u.id
LEFT JOIN user_votes_received vr
    ON vr.userid = u.id
LEFT JOIN user_votes_cast vc
    ON vc.userid = u.id
LEFT JOIN user_tags_used tg
    ON tg.userid = u.id
LEFT JOIN user_posthistory ph
    ON ph.userid = u.id
LEFT JOIN user_postlinks pl
    ON pl.userid = u.id
ORDER BY badge_count DESC
LIMIT 10
