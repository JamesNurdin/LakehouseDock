/*
  Analytical query: summary of user activity and contributions.
  It aggregates badges, owned posts, edited posts, votes cast/received, and post‑history actions per user.
*/
WITH user_base AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        u.creationdate,
        u.views,
        u.upvotes,
        u.downvotes
    FROM users u
),
badge_counts AS (
    SELECT
        b.userid AS user_id,
        COUNT(b.id) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
post_counts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(p.id) AS post_owned_count,
        SUM(p.score) AS total_owned_score
    FROM posts p
    GROUP BY p.owneruserid
),
edited_counts AS (
    SELECT
        p.lasteditoruserid AS user_id,
        COUNT(p.id) AS post_edited_count
    FROM posts p
    GROUP BY p.lasteditoruserid
),
vote_cast_counts AS (
    SELECT
        v.userid AS user_id,
        COUNT(v.id) AS votes_cast_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast_count
    FROM votes v
    GROUP BY v.userid
),
vote_received_counts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(v.id) AS votes_received_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_received_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_received_count
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
posthistory_counts AS (
    SELECT
        ph.userid AS user_id,
        COUNT(ph.id) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
),
posthistory_post_counts AS (
    SELECT
        ph.userid AS user_id,
        COUNT(ph.id) AS posthistory_post_ref_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY ph.userid
)
SELECT
    ub.user_id,
    ub.reputation,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(pc.post_owned_count, 0) AS post_owned_count,
    COALESCE(pc.total_owned_score, 0) AS total_owned_score,
    COALESCE(ec.post_edited_count, 0) AS post_edited_count,
    COALESCE(vcc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vcc.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(vcc.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(vrc.votes_received_count, 0) AS votes_received_count,
    COALESCE(vrc.upvote_received_count, 0) AS upvote_received_count,
    COALESCE(vrc.downvote_received_count, 0) AS downvote_received_count,
    COALESCE(phc.posthistory_count, 0) AS posthistory_count,
    COALESCE(phpc.posthistory_post_ref_count, 0) AS posthistory_post_ref_count
FROM user_base ub
LEFT JOIN badge_counts bc ON bc.user_id = ub.user_id
LEFT JOIN post_counts pc ON pc.user_id = ub.user_id
LEFT JOIN edited_counts ec ON ec.user_id = ub.user_id
LEFT JOIN vote_cast_counts vcc ON vcc.user_id = ub.user_id
LEFT JOIN vote_received_counts vrc ON vrc.user_id = ub.user_id
LEFT JOIN posthistory_counts phc ON phc.user_id = ub.user_id
LEFT JOIN posthistory_post_counts phpc ON phpc.user_id = ub.user_id
ORDER BY ub.reputation DESC
LIMIT 10
