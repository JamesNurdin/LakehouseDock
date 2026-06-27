WITH
    post_metrics AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            AVG(score) AS avg_post_score,
            SUM(viewcount) AS total_views
        FROM posts
        GROUP BY owneruserid
    ),
    edit_metrics AS (
        SELECT
            lasteditoruserid AS userid,
            COUNT(*) AS edit_count
        FROM posts
        GROUP BY lasteditoruserid
    ),
    votes_received AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(v.id) AS votes_received,
            SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    votes_cast AS (
        SELECT
            userid,
            COUNT(*) AS votes_cast,
            SUM(COALESCE(bountyamount, 0)) AS total_bounty_cast
        FROM votes
        GROUP BY userid
    ),
    comment_metrics AS (
        SELECT
            userid,
            COUNT(*) AS comment_count,
            SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    badge_metrics AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    posthistory_metrics AS (
        SELECT
            userid,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    tag_metrics AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(DISTINCT t.id) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    postlink_metrics AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(pl.id) AS link_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.total_post_score, 0) AS total_post_score,
    COALESCE(pm.avg_post_score, 0) AS avg_post_score,
    COALESCE(pm.total_views, 0) AS total_views,
    COALESCE(em.edit_count, 0) AS edit_count,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.total_bounty_cast, 0) AS total_bounty_cast,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(cm.total_comment_score, 0) AS total_comment_score,
    COALESCE(bm.badge_count, 0) AS badge_count,
    COALESCE(phm.posthistory_count, 0) AS posthistory_count,
    COALESCE(tm.tag_count, 0) AS tag_count,
    COALESCE(plm.link_count, 0) AS post_link_count
FROM users u
LEFT JOIN post_metrics pm ON u.id = pm.userid
LEFT JOIN edit_metrics em ON u.id = em.userid
LEFT JOIN votes_received vr ON u.id = vr.userid
LEFT JOIN votes_cast vc ON u.id = vc.userid
LEFT JOIN comment_metrics cm ON u.id = cm.userid
LEFT JOIN badge_metrics bm ON u.id = bm.userid
LEFT JOIN posthistory_metrics phm ON u.id = phm.userid
LEFT JOIN tag_metrics tm ON u.id = tm.userid
LEFT JOIN postlink_metrics plm ON u.id = plm.userid
ORDER BY total_post_score DESC
LIMIT 100
