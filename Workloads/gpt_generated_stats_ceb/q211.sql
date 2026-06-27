WITH post_stats AS (
    SELECT
        ph.userid,
        COUNT(*) AS posthistory_count,
        SUM(CASE WHEN ph.posthistorytypeid = 1 THEN 1 ELSE 0 END) AS post_created,
        MIN(ph.creationdate) AS first_posthistory,
        MAX(ph.creationdate) AS last_posthistory
    FROM posthistory ph
    JOIN users u ON ph.userid = u.id
    GROUP BY ph.userid
),
vote_stats AS (
    SELECT
        v.userid,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast,
        MIN(v.creationdate) AS first_vote,
        MAX(v.creationdate) AS last_vote
    FROM votes v
    JOIN users u ON v.userid = u.id
    GROUP BY v.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creationdate,
    COALESCE(ps.posthistory_count, 0) AS posthistory_count,
    COALESCE(ps.post_created, 0) AS post_created,
    ps.first_posthistory,
    ps.last_posthistory,
    COALESCE(vs.vote_count, 0) AS vote_count,
    COALESCE(vs.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vs.downvotes_cast, 0) AS downvotes_cast,
    vs.first_vote,
    vs.last_vote,
    CASE WHEN vs.downvotes_cast > 0 THEN vs.upvotes_cast * 1.0 / vs.downvotes_cast ELSE NULL END AS up_down_ratio
FROM users u
LEFT JOIN post_stats ps ON ps.userid = u.id
LEFT JOIN vote_stats vs ON vs.userid = u.id
ORDER BY vote_count DESC, posthistory_count DESC
LIMIT 50
