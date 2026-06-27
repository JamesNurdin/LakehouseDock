WITH badges_per_user AS (
    SELECT
        userid,
        COUNT(id) AS badge_count
    FROM badges
    GROUP BY userid
),
posts_owned AS (
    SELECT
        owneruserid AS userid,
        COUNT(id) AS owned_post_count,
        AVG(score) AS avg_owned_score,
        SUM(viewcount) AS total_owned_views
    FROM posts
    GROUP BY owneruserid
),
posts_edited AS (
    SELECT
        lasteditoruserid AS userid,
        COUNT(id) AS edited_post_count,
        AVG(score) AS avg_edited_score
    FROM posts
    GROUP BY lasteditoruserid
),
posthistory_events AS (
    SELECT
        userid,
        COUNT(id) AS ph_event_count,
        COUNT(DISTINCT posthistorytypeid) AS distinct_ph_type_count
    FROM posthistory
    GROUP BY userid
),
posthistory_posts AS (
    SELECT
        ph.userid,
        COUNT(DISTINCT p.id) AS distinct_referenced_posts
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY ph.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(po.owned_post_count, 0) AS owned_post_count,
    COALESCE(po.avg_owned_score, 0) AS avg_owned_score,
    COALESCE(po.total_owned_views, 0) AS total_owned_views,
    COALESCE(pe.edited_post_count, 0) AS edited_post_count,
    COALESCE(pe.avg_edited_score, 0) AS avg_edited_score,
    COALESCE(ph.ph_event_count, 0) AS posthistory_event_count,
    COALESCE(ph.distinct_ph_type_count, 0) AS distinct_posthistory_type_count,
    COALESCE(pp.distinct_referenced_posts, 0) AS distinct_referenced_posts,
    RANK() OVER (ORDER BY u.reputation DESC) AS reputation_rank
FROM users u
LEFT JOIN badges_per_user b ON b.userid = u.id
LEFT JOIN posts_owned po ON po.userid = u.id
LEFT JOIN posts_edited pe ON pe.userid = u.id
LEFT JOIN posthistory_events ph ON ph.userid = u.id
LEFT JOIN posthistory_posts pp ON pp.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
