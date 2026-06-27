WITH comment_stats AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count,
        AVG(c.score) AS avg_comment_score,
        SUM(c.score) AS total_comment_score,
        MIN(c.creationdate) AS first_comment_date,
        MAX(c.creationdate) AS last_comment_date
    FROM comments c
    GROUP BY c.userid
),
history_stats AS (
    SELECT
        p.userid AS user_id,
        COUNT(*) AS history_event_count,
        COUNT(DISTINCT p.posthistorytypeid) AS distinct_history_type_count,
        SUM(CASE WHEN p.posthistorytypeid = 1 THEN 1 ELSE 0 END) AS history_type_1_count,
        SUM(CASE WHEN p.posthistorytypeid = 2 THEN 1 ELSE 0 END) AS history_type_2_count
    FROM posthistory p
    GROUP BY p.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate AS user_creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(cs.comment_count, 0) AS comment_count,
    cs.avg_comment_score,
    cs.total_comment_score,
    cs.first_comment_date,
    cs.last_comment_date,
    COALESCE(hs.history_event_count, 0) AS history_event_count,
    hs.distinct_history_type_count,
    hs.history_type_1_count,
    hs.history_type_2_count,
    CASE WHEN COALESCE(hs.history_event_count, 0) = 0 THEN NULL
         ELSE cs.comment_count * 1.0 / hs.history_event_count END AS comments_per_history_event
FROM users u
LEFT JOIN comment_stats cs ON u.id = cs.user_id
LEFT JOIN history_stats hs ON u.id = hs.user_id
WHERE u.reputation > 0
ORDER BY comment_count DESC
LIMIT 200
