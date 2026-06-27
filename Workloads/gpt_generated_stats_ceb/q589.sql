WITH post_metrics AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        COALESCE(SUM(score), 0) AS post_score_sum,
        COALESCE(AVG(score), 0) AS post_score_avg
    FROM posts
    GROUP BY owneruserid
),
comment_metrics AS (
    SELECT
        userid,
        COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
vote_cast_metrics AS (
    SELECT
        userid,
        COUNT(*) AS vote_cast_count,
        COALESCE(SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvote_cast_count,
        COALESCE(SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvote_cast_count,
        COALESCE(SUM(bountyamount), 0) AS bounty_amount_cast
    FROM votes
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
postlink_metrics AS (
    SELECT
        userid,
        COUNT(*) AS postlink_count
    FROM (
        SELECT p.owneruserid AS userid
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        UNION ALL
        SELECT p.owneruserid AS userid
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
    ) t
    GROUP BY userid
),
tag_metrics AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(t.id) AS tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
vote_received_metrics AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(v.id) AS votes_received_count,
        COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_received,
        COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.post_score_sum, 0) AS post_score_sum,
    COALESCE(pm.post_score_avg, 0) AS post_score_avg,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(vcm.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(vcm.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(vcm.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(vcm.bounty_amount_cast, 0) AS bounty_amount_cast,
    COALESCE(bm.badge_count, 0) AS badge_count,
    COALESCE(phm.posthistory_count, 0) AS posthistory_count,
    COALESCE(plm.postlink_count, 0) AS postlink_count,
    COALESCE(tm.tag_count, 0) AS tag_count,
    COALESCE(vrm.votes_received_count, 0) AS votes_received_count,
    COALESCE(vrm.upvotes_received, 0) AS upvotes_received,
    COALESCE(vrm.downvotes_received, 0) AS downvotes_received
FROM users u
LEFT JOIN post_metrics pm ON u.id = pm.userid
LEFT JOIN comment_metrics cm ON u.id = cm.userid
LEFT JOIN vote_cast_metrics vcm ON u.id = vcm.userid
LEFT JOIN badge_metrics bm ON u.id = bm.userid
LEFT JOIN posthistory_metrics phm ON u.id = phm.userid
LEFT JOIN postlink_metrics plm ON u.id = plm.userid
LEFT JOIN tag_metrics tm ON u.id = tm.userid
LEFT JOIN vote_received_metrics vrm ON u.id = vrm.userid
ORDER BY post_score_sum DESC
LIMIT 100
