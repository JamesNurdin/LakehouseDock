WITH ph_user AS (
    SELECT
        ph.posthistorytypeid,
        ph.userid,
        u.reputation,
        u.views,
        u.upvotes,
        u.downvotes,
        ph.creationdate
    FROM posthistory ph
    JOIN users u
      ON ph.userid = u.id
)
SELECT
    posthistorytypeid,
    event_count,
    distinct_user_count,
    avg_user_reputation,
    total_user_views,
    total_user_upvotes,
    total_user_downvotes,
    earliest_event,
    latest_event,
    RANK() OVER (ORDER BY event_count DESC) AS event_count_rank
FROM (
    SELECT
        posthistorytypeid,
        COUNT(*) AS event_count,
        COUNT(DISTINCT userid) AS distinct_user_count,
        AVG(reputation) AS avg_user_reputation,
        SUM(views) AS total_user_views,
        SUM(upvotes) AS total_user_upvotes,
        SUM(downvotes) AS total_user_downvotes,
        MIN(creationdate) AS earliest_event,
        MAX(creationdate) AS latest_event
    FROM ph_user
    GROUP BY posthistorytypeid
) agg
ORDER BY event_count DESC
