WITH owned_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS owned_post_count,
        COALESCE(SUM(p.score), 0) AS owned_post_score_sum,
        COUNT(DISTINCT t.id) AS distinct_tags_used_count
    FROM posts p
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
edited_posts AS (
    SELECT
        p.lasteditoruserid AS user_id,
        COUNT(*) AS edited_post_count
    FROM posts p
    GROUP BY p.lasteditoruserid
),
votes_cast AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast_count
    FROM votes v
    GROUP BY v.userid
),
votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
comments_made AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comments_made_count
    FROM comments c
    GROUP BY c.userid
),
comments_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS comments_received_count
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
),
badges_earned AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
posthistory_actions AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
),
postlinks_owned AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS postlinks_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(op.owned_post_count, 0) AS owned_post_count,
    COALESCE(op.owned_post_score_sum, 0) AS owned_post_score_sum,
    COALESCE(ep.edited_post_count, 0) AS edited_post_count,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(cm.comments_made_count, 0) AS comments_made_count,
    COALESCE(cr.comments_received_count, 0) AS comments_received_count,
    COALESCE(be.badge_count, 0) AS badge_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(pl.postlinks_count, 0) AS postlinks_count,
    COALESCE(op.distinct_tags_used_count, 0) AS distinct_tags_used_count,
    DENSE_RANK() OVER (ORDER BY COALESCE(op.owned_post_score_sum, 0) DESC) AS score_rank
FROM users u
LEFT JOIN owned_posts op ON op.user_id = u.id
LEFT JOIN edited_posts ep ON ep.user_id = u.id
LEFT JOIN votes_cast vc ON vc.user_id = u.id
LEFT JOIN votes_received vr ON vr.user_id = u.id
LEFT JOIN comments_made cm ON cm.user_id = u.id
LEFT JOIN comments_received cr ON cr.user_id = u.id
LEFT JOIN badges_earned be ON be.user_id = u.id
LEFT JOIN posthistory_actions ph ON ph.user_id = u.id
LEFT JOIN postlinks_owned pl ON pl.user_id = u.id
ORDER BY owned_post_score_sum DESC
LIMIT 100
