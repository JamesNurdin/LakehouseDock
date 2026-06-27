WITH
    post_metrics AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(score) AS post_score_sum,
            AVG(score) AS post_score_avg
        FROM posts
        GROUP BY owneruserid
    ),
    comment_metrics AS (
        SELECT
            userid,
            COUNT(*) AS comment_count,
            SUM(score) AS comment_score_sum,
            AVG(score) AS comment_score_avg
        FROM comments
        GROUP BY userid
    ),
    vote_cast_metrics AS (
        SELECT
            userid,
            COUNT(*) AS votes_cast_count
        FROM votes
        GROUP BY userid
    ),
    vote_received_metrics AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS votes_received_count
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    badge_metrics AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    tag_metrics AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(DISTINCT t.id) AS tag_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.post_score_sum, 0) AS post_score_sum,
    COALESCE(pm.post_score_avg, 0) AS post_score_avg,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(cm.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(cm.comment_score_avg, 0) AS comment_score_avg,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(bm.badge_count, 0) AS badge_count,
    COALESCE(tm.tag_count, 0) AS tag_count,
    (
        COALESCE(pm.post_score_sum, 0) +
        COALESCE(cm.comment_score_sum, 0) +
        COALESCE(vc.votes_cast_count, 0) +
        COALESCE(vr.votes_received_count, 0) +
        COALESCE(bm.badge_count, 0)
    ) AS activity_score
FROM users u
LEFT JOIN post_metrics pm ON pm.userid = u.id
LEFT JOIN comment_metrics cm ON cm.userid = u.id
LEFT JOIN vote_cast_metrics vc ON vc.userid = u.id
LEFT JOIN vote_received_metrics vr ON vr.userid = u.id
LEFT JOIN badge_metrics bm ON bm.userid = u.id
LEFT JOIN tag_metrics tm ON tm.userid = u.id
ORDER BY activity_score DESC
LIMIT 10
