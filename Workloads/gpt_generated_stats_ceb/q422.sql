WITH badge_counts AS (
    SELECT userid, COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
post_owner_stats AS (
    SELECT owneruserid,
           COUNT(*) AS post_count,
           SUM(score) AS total_score,
           AVG(score) AS avg_score,
           SUM(viewcount) AS total_viewcount,
           SUM(favoritecount) AS total_favoritecount
    FROM posts
    GROUP BY owneruserid
),
post_editor_stats AS (
    SELECT lasteditoruserid, COUNT(*) AS edited_post_count
    FROM posts
    GROUP BY lasteditoruserid
),
comment_counts AS (
    SELECT userid, COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
vote_cast_counts AS (
    SELECT userid, COUNT(*) AS votes_cast_count
    FROM votes
    GROUP BY userid
),
vote_received_counts AS (
    SELECT p.owneruserid AS userid, COUNT(*) AS votes_received_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
posthistory_counts AS (
    SELECT userid, COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(pos.post_count, 0) AS post_count,
    COALESCE(pos.avg_score, 0) AS avg_post_score,
    COALESCE(pos.total_viewcount, 0) AS total_viewcount,
    COALESCE(pos.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(pes.edited_post_count, 0) AS edited_post_count,
    COALESCE(cc.comment_count, 0) AS comment_count,
    COALESCE(vcc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vrc.votes_received_count, 0) AS votes_received_count,
    COALESCE(phc.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN badge_counts bc ON u.id = bc.userid
LEFT JOIN post_owner_stats pos ON u.id = pos.owneruserid
LEFT JOIN post_editor_stats pes ON u.id = pes.lasteditoruserid
LEFT JOIN comment_counts cc ON u.id = cc.userid
LEFT JOIN vote_cast_counts vcc ON u.id = vcc.userid
LEFT JOIN vote_received_counts vrc ON u.id = vrc.userid
LEFT JOIN posthistory_counts phc ON u.id = phc.userid
ORDER BY u.reputation DESC
LIMIT 100
