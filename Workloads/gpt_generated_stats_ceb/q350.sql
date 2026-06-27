WITH post_counts AS (
    SELECT owneruserid, COUNT(*) AS post_count
    FROM posts
    GROUP BY owneruserid
),
comment_counts AS (
    SELECT userid, COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
vote_counts AS (
    SELECT userid, COUNT(*) AS vote_cast_count
    FROM votes
    GROUP BY userid
),
badge_counts AS (
    SELECT userid, COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
posthistory_counts AS (
    SELECT userid, COUNT(*) AS post_history_count
    FROM posthistory
    GROUP BY userid
),
postlink_counts AS (
    SELECT p.owneruserid, COUNT(*) AS post_link_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
edited_post_counts AS (
    SELECT lasteditoruserid, COUNT(*) AS edited_post_count
    FROM posts
    GROUP BY lasteditoruserid
),
posthistory_post_counts AS (
    SELECT ph.userid, COUNT(*) AS post_history_type_link_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY ph.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(pc.post_count, 0) AS post_count,
    COALESCE(cc.comment_count, 0) AS comment_count,
    COALESCE(vc.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(phc.post_history_count, 0) AS post_history_count,
    COALESCE(plc.post_link_count, 0) AS post_link_count,
    COALESCE(epc.edited_post_count, 0) AS edited_post_count,
    COALESCE(phpc.post_history_type_link_count, 0) AS post_history_type_link_count,
    (
        COALESCE(pc.post_count, 0) +
        COALESCE(cc.comment_count, 0) +
        COALESCE(vc.vote_cast_count, 0) +
        COALESCE(bc.badge_count, 0) +
        COALESCE(phc.post_history_count, 0) +
        COALESCE(plc.post_link_count, 0) +
        COALESCE(epc.edited_post_count, 0) +
        COALESCE(phpc.post_history_type_link_count, 0)
    ) AS total_activity
FROM users u
LEFT JOIN post_counts pc ON pc.owneruserid = u.id
LEFT JOIN comment_counts cc ON cc.userid = u.id
LEFT JOIN vote_counts vc ON vc.userid = u.id
LEFT JOIN badge_counts bc ON bc.userid = u.id
LEFT JOIN posthistory_counts phc ON phc.userid = u.id
LEFT JOIN postlink_counts plc ON plc.owneruserid = u.id
LEFT JOIN edited_post_counts epc ON epc.lasteditoruserid = u.id
LEFT JOIN posthistory_post_counts phpc ON phpc.userid = u.id
ORDER BY total_activity DESC
LIMIT 10
