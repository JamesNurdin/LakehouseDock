WITH
    badge_counts AS (
        SELECT userid,
               COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    post_stats AS (
        SELECT owneruserid,
               COUNT(*) AS post_count,
               AVG(score) AS avg_post_score
        FROM posts
        GROUP BY owneruserid
    ),
    edited_posts AS (
        SELECT lasteditoruserid,
               COUNT(*) AS edited_post_count
        FROM posts
        GROUP BY lasteditoruserid
    ),
    votes_cast AS (
        SELECT userid,
               COUNT(*) AS votes_cast_count
        FROM votes
        GROUP BY userid
    ),
    votes_received AS (
        SELECT p.owneruserid,
               COUNT(*) AS votes_received_count
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    comments_made AS (
        SELECT userid,
               COUNT(*) AS comments_made_count
        FROM comments
        GROUP BY userid
    ),
    comments_received AS (
        SELECT p.owneruserid,
               COUNT(*) AS comments_received_count
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    tag_excerpts AS (
        SELECT p.owneruserid,
               COUNT(DISTINCT t.id) AS tag_excerpts_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    posthistory_counts AS (
        SELECT userid,
               COUNT(*) AS post_history_count
        FROM posthistory
        GROUP BY userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    ROW_NUMBER() OVER (ORDER BY u.reputation DESC) AS reputation_rank,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.avg_post_score, 0) AS avg_post_score,
    COALESCE(ep.edited_post_count, 0) AS edited_post_count,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(cm.comments_made_count, 0) AS comments_made_count,
    COALESCE(cr.comments_received_count, 0) AS comments_received_count,
    COALESCE(te.tag_excerpts_count, 0) AS tag_excerpts_count,
    COALESCE(phc.post_history_count, 0) AS post_history_count
FROM users u
LEFT JOIN badge_counts bc      ON bc.userid = u.id
LEFT JOIN post_stats ps        ON ps.owneruserid = u.id
LEFT JOIN edited_posts ep      ON ep.lasteditoruserid = u.id
LEFT JOIN votes_cast vc        ON vc.userid = u.id
LEFT JOIN votes_received vr    ON vr.owneruserid = u.id
LEFT JOIN comments_made cm     ON cm.userid = u.id
LEFT JOIN comments_received cr ON cr.owneruserid = u.id
LEFT JOIN tag_excerpts te      ON te.owneruserid = u.id
LEFT JOIN posthistory_counts phc ON phc.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
