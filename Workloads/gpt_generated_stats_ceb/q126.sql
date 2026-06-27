WITH
    post_metrics AS (
        SELECT
            owneruserid AS user_id,
            COUNT(*) AS post_count,
            COALESCE(SUM(score), 0) AS total_post_score
        FROM posts
        GROUP BY owneruserid
    ),
    comment_metrics AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS comment_count,
            COALESCE(SUM(score), 0) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    badge_metrics AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    votes_cast_metrics AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS votes_cast
        FROM votes
        GROUP BY userid
    ),
    votes_received_metrics AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(v.id) AS votes_received,
            COALESCE(SUM(v.bountyamount), 0) AS total_bounty_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    posthistory_metrics AS (
        SELECT
            userid AS user_id,
            COUNT(*) AS post_edits
        FROM posthistory
        GROUP BY userid
    ),
    postlinks_initiated_metrics AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_links_initiated
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    postlinks_received_metrics AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_links_received
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.total_post_score, 0) AS total_post_score,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(cm.total_comment_score, 0) AS total_comment_score,
    COALESCE(bm.badge_count, 0) AS badge_count,
    COALESCE(vcm.votes_cast, 0) AS votes_cast,
    COALESCE(vrm.votes_received, 0) AS votes_received,
    COALESCE(vrm.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(phm.post_edits, 0) AS post_edits,
    COALESCE(plim.post_links_initiated, 0) AS post_links_initiated,
    COALESCE(plrm.post_links_received, 0) AS post_links_received
FROM users u
LEFT JOIN post_metrics pm ON pm.user_id = u.id
LEFT JOIN comment_metrics cm ON cm.user_id = u.id
LEFT JOIN badge_metrics bm ON bm.user_id = u.id
LEFT JOIN votes_cast_metrics vcm ON vcm.user_id = u.id
LEFT JOIN votes_received_metrics vrm ON vrm.user_id = u.id
LEFT JOIN posthistory_metrics phm ON phm.user_id = u.id
LEFT JOIN postlinks_initiated_metrics plim ON plim.user_id = u.id
LEFT JOIN postlinks_received_metrics plrm ON plrm.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 10
