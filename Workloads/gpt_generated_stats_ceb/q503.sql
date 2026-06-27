WITH ph AS (
    SELECT
        ph.userid,
        COUNT(*) AS ph_event_count,
        COUNT(DISTINCT ph.postid) AS distinct_posts,
        SUM(CASE WHEN ph.posthistorytypeid = 2 THEN 1 ELSE 0 END) AS edit_events
    FROM posthistory ph
    GROUP BY ph.userid
),
v AS (
    SELECT
        v.userid,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast,
        SUM(v.bountyamount) AS total_bounty_given
    FROM votes v
    GROUP BY v.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.views,
    u.upvotes AS user_upvotes_received,
    u.downvotes AS user_downvotes_received,
    COALESCE(ph.ph_event_count, 0) AS posthistory_event_count,
    COALESCE(ph.distinct_posts, 0) AS distinct_posts_affected,
    COALESCE(ph.edit_events, 0) AS edit_events,
    COALESCE(v.vote_count, 0) AS votes_cast,
    COALESCE(v.upvote_cast, 0) AS upvotes_cast,
    COALESCE(v.downvote_cast, 0) AS downvotes_cast,
    COALESCE(v.total_bounty_given, 0) AS total_bounty_given,
    RANK() OVER (ORDER BY COALESCE(ph.ph_event_count, 0) DESC) AS ph_event_rank
FROM users u
LEFT JOIN ph ON ph.userid = u.id
LEFT JOIN v ON v.userid = u.id
ORDER BY posthistory_event_count DESC, votes_cast DESC
LIMIT 100
