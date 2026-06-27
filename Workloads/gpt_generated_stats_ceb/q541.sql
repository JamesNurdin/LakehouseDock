WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(CASE WHEN p.posttypeid = 2 THEN 1 ELSE 0 END) AS answer_count,
        SUM(p.score) AS total_post_score,
        SUM(p.viewcount) AS total_view_count,
        SUM(p.favoritecount) AS total_favorite_count
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments_made AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_made_count
    FROM comments c
    GROUP BY c.userid
),
user_comments_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS comment_received_count
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
),
user_votes_cast AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast_count
    FROM votes v
    GROUP BY v.userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_posthistory AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_postlinks_source AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS postlinks_source_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_postlinks_target AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS postlinks_target_count
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.answer_count, 0) AS answer_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_view_count, 0) AS total_view_count,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(cm.comment_made_count, 0) AS comment_made_count,
    COALESCE(cr.comment_received_count, 0) AS comment_received_count,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(pls.postlinks_source_count, 0) AS postlinks_source_count,
    COALESCE(plt.postlinks_target_count, 0) AS postlinks_target_count
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments_made cm ON cm.user_id = u.id
LEFT JOIN user_comments_received cr ON cr.user_id = u.id
LEFT JOIN user_votes_cast vc ON vc.user_id = u.id
LEFT JOIN user_votes_received vr ON vr.user_id = u.id
LEFT JOIN user_badges b ON b.user_id = u.id
LEFT JOIN user_posthistory ph ON ph.user_id = u.id
LEFT JOIN user_postlinks_source pls ON pls.user_id = u.id
LEFT JOIN user_postlinks_target plt ON plt.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
