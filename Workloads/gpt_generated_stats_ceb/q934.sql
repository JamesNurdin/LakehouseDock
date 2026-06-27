WITH comment_counts AS (
    SELECT postid, COUNT(*) AS comment_count
    FROM comments
    GROUP BY postid
),
vote_counts AS (
    SELECT postid, COUNT(*) AS vote_count
    FROM votes
    GROUP BY postid
),
posthistory_counts AS (
    SELECT posthistorytypeid AS post_id, COUNT(*) AS history_count
    FROM posthistory
    GROUP BY posthistorytypeid
),
postlink_counts AS (
    SELECT post_id, COUNT(*) AS link_count
    FROM (
        SELECT postid AS post_id FROM postlinks
        UNION ALL
        SELECT relatedpostid AS post_id FROM postlinks
    ) pl
    GROUP BY post_id
),
owner_badge_counts AS (
    SELECT p.owneruserid AS owner_user_id, COUNT(*) AS owner_badge_count
    FROM posts p
    JOIN users u ON p.owneruserid = u.id
    JOIN badges b ON b.userid = u.id
    GROUP BY p.owneruserid
)
SELECT
    t.id AS tag_id,
    t.count AS tag_use_count,
    COUNT(p.id) AS post_count,
    SUM(p.score) AS total_post_score,
    AVG(p.score) AS avg_post_score,
    COUNT(DISTINCT p.owneruserid) AS distinct_owner_user_count,
    COUNT(DISTINCT p.lasteditoruserid) AS distinct_editor_user_count,
    COALESCE(SUM(cc.comment_count), 0) AS total_comment_count,
    COALESCE(SUM(vc.vote_count), 0) AS total_vote_count,
    COALESCE(SUM(phc.history_count), 0) AS total_posthistory_count,
    COALESCE(SUM(plc.link_count), 0) AS total_postlink_count,
    COALESCE(SUM(obc.owner_badge_count), 0) AS total_owner_badge_count
FROM tags t
JOIN posts p ON t.excerptpostid = p.id
LEFT JOIN comment_counts cc ON cc.postid = p.id
LEFT JOIN vote_counts vc ON vc.postid = p.id
LEFT JOIN posthistory_counts phc ON phc.post_id = p.id
LEFT JOIN postlink_counts plc ON plc.post_id = p.id
LEFT JOIN owner_badge_counts obc ON obc.owner_user_id = p.owneruserid
GROUP BY t.id, t.count
ORDER BY total_post_score DESC
LIMIT 100
