WITH user_base AS (
    SELECT id,
           reputation
    FROM users
),
post_counts AS (
    SELECT owneruserid AS id,
           COUNT(*) AS post_count,
           AVG(score) AS avg_post_score
    FROM posts
    GROUP BY owneruserid
),
answer_counts AS (
    SELECT owneruserid AS id,
           COUNT(*) FILTER (WHERE posttypeid = 2) AS answer_count
    FROM posts
    GROUP BY owneruserid
),
badge_counts AS (
    SELECT userid AS id,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
vote_cast_counts AS (
    SELECT userid AS id,
           COUNT(*) AS votes_cast
    FROM votes
    GROUP BY userid
),
vote_received_counts AS (
    SELECT p.owneruserid AS id,
           COUNT(*) AS votes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
post_edit_counts AS (
    SELECT lasteditoruserid AS id,
           COUNT(*) AS edit_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
),
posthistory_counts AS (
    SELECT userid AS id,
           COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
),
posthistory_edit_counts AS (
    SELECT ph.userid AS id,
           COUNT(*) AS posthistory_edit_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY ph.userid
)
SELECT 
    u.id,
    u.reputation,
    COALESCE(pc.post_count, 0) AS post_count,
    COALESCE(pc.avg_post_score, 0) AS avg_post_score,
    COALESCE(ac.answer_count, 0) AS answer_count,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(ec.edit_count, 0) AS edit_count,
    COALESCE(phc.posthistory_count, 0) AS posthistory_count,
    COALESCE(phe.posthistory_edit_count, 0) AS posthistory_edit_count
FROM user_base u
LEFT JOIN post_counts pc ON u.id = pc.id
LEFT JOIN answer_counts ac ON u.id = ac.id
LEFT JOIN badge_counts bc ON u.id = bc.id
LEFT JOIN vote_cast_counts vc ON u.id = vc.id
LEFT JOIN vote_received_counts vr ON u.id = vr.id
LEFT JOIN post_edit_counts ec ON u.id = ec.id
LEFT JOIN posthistory_counts phc ON u.id = phc.id
LEFT JOIN posthistory_edit_counts phe ON u.id = phe.id
ORDER BY u.reputation DESC
LIMIT 100
