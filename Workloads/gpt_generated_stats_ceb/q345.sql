WITH post_metrics AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_post_score,
        SUM(p.viewcount) AS total_view_count,
        SUM(p.answercount) AS total_answer_count,
        SUM(p.commentcount) AS total_post_comment_count,
        SUM(p.favoritecount) AS total_favorite_count
    FROM posts p
    GROUP BY p.owneruserid
),
comment_metrics AS (
    SELECT
        c.userid AS userid,
        COUNT(*) AS comment_count,
        SUM(c.score) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
vote_metrics AS (
    SELECT
        v.userid AS userid,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_count
    FROM votes v
    GROUP BY v.userid
),
badge_metrics AS (
    SELECT
        b.userid AS userid,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
posthistory_metrics AS (
    SELECT
        ph.userid AS userid,
        COUNT(*) AS posthistory_event_count
    FROM posthistory ph
    GROUP BY ph.userid
),
tag_metrics AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS tag_created_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
postlink_counts AS (
    SELECT
        userid,
        SUM(postlink_count) AS total_postlink_count
    FROM (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
        UNION ALL
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    ) sub
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.total_post_score, 0) AS total_post_score,
    COALESCE(pm.total_view_count, 0) AS total_view_count,
    COALESCE(pm.total_answer_count, 0) AS total_answer_count,
    COALESCE(pm.total_post_comment_count, 0) AS total_post_comment_count,
    COALESCE(pm.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(cm.total_comment_score, 0) AS total_comment_score,
    COALESCE(vm.upvote_count, 0) AS upvote_count,
    COALESCE(vm.downvote_count, 0) AS downvote_count,
    COALESCE(bm.badge_count, 0) AS badge_count,
    COALESCE(phm.posthistory_event_count, 0) AS posthistory_event_count,
    COALESCE(tm.tag_created_count, 0) AS tag_created_count,
    COALESCE(plc.total_postlink_count, 0) AS total_postlink_count,
    (COALESCE(pm.total_post_score, 0) +
     COALESCE(cm.total_comment_score, 0) +
     COALESCE(vm.upvote_count, 0) * 10 +
     COALESCE(bm.badge_count, 0) * 5 +
     COALESCE(plc.total_postlink_count, 0) * 2) AS activity_score
FROM users u
LEFT JOIN post_metrics pm ON pm.userid = u.id
LEFT JOIN comment_metrics cm ON cm.userid = u.id
LEFT JOIN vote_metrics vm ON vm.userid = u.id
LEFT JOIN badge_metrics bm ON bm.userid = u.id
LEFT JOIN posthistory_metrics phm ON phm.userid = u.id
LEFT JOIN tag_metrics tm ON tm.userid = u.id
LEFT JOIN postlink_counts plc ON plc.userid = u.id
WHERE u.reputation > 1000
ORDER BY activity_score DESC
LIMIT 10
