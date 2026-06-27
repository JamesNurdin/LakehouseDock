WITH user_posts AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(score) AS total_score,
        AVG(score) AS avg_score
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
        COUNT(*) AS votes_received_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_comments_received AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS comments_received_count
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT
        userid,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
user_edits AS (
    SELECT
        lasteditoruserid AS userid,
        COUNT(*) AS edit_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT t.id) AS distinct_tag_count,
        SUM(t.count) AS tag_total_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_links AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_links_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_score, 0) AS total_post_score,
    COALESCE(up.avg_score, 0) AS avg_post_score,
    COALESCE(cm.comment_made_count, 0) AS comment_made_count,
    COALESCE(cr.comments_received_count, 0) AS comments_received_count,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(t.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(t.tag_total_count, 0) AS tag_total_count,
    COALESCE(l.post_links_count, 0) AS post_links_count
FROM users u
LEFT JOIN user_posts up ON u.id = up.userid
LEFT JOIN user_comments_made cm ON u.id = cm.userid
LEFT JOIN user_comments_received cr ON u.id = cr.userid
LEFT JOIN user_votes_cast vc ON u.id = vc.userid
LEFT JOIN user_votes_received vr ON u.id = vr.userid
LEFT JOIN user_badges b ON u.id = b.userid
LEFT JOIN user_posthistory ph ON u.id = ph.userid
LEFT JOIN user_edits e ON u.id = e.userid
LEFT JOIN user_tags t ON u.id = t.userid
LEFT JOIN user_links l ON u.id = l.userid
ORDER BY total_post_score DESC
LIMIT 100
