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
        COUNT(DISTINCT b.id) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
post_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT p.id) FILTER (WHERE p.posttypeid = 1) AS question_count,
        COUNT(DISTINCT p.id) FILTER (WHERE p.posttypeid = 2) AS answer_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_post_views
    FROM posts p
    GROUP BY p.owneruserid
),
vote_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT v.id) AS votes_received,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
vote_cast AS (
    SELECT
        v.userid AS user_id,
        COUNT(DISTINCT v.id) AS votes_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes v
    GROUP BY v.userid
),
posthistory_counts AS (
    SELECT
        ph.userid AS user_id,
        COUNT(DISTINCT ph.id) AS posthistory_event_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY ph.userid
)
SELECT
    ub.user_id,
    ub.reputation,
    ub.creationdate,
    ub.views,
    ub.upvotes,
    ub.downvotes,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(ps.question_count, 0) AS question_count,
    COALESCE(ps.answer_count, 0) AS answer_count,
    COALESCE(ps.total_post_score, 0) AS total_post_score,
    COALESCE(ps.total_post_views, 0) AS total_post_views,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(phc.posthistory_event_count, 0) AS posthistory_event_count
FROM user_base ub
LEFT JOIN badge_counts bc ON bc.user_id = ub.user_id
LEFT JOIN post_stats ps ON ps.user_id = ub.user_id
LEFT JOIN vote_received vr ON vr.user_id = ub.user_id
LEFT JOIN vote_cast vc ON vc.user_id = ub.user_id
LEFT JOIN posthistory_counts phc ON phc.user_id = ub.user_id
ORDER BY ub.reputation DESC
LIMIT 100
