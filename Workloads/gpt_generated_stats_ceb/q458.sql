WITH badge_counts AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
owned_posts AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS owned_post_count,
           SUM(score) AS owned_post_score,
           AVG(viewcount) AS avg_viewcount
    FROM posts
    GROUP BY owneruserid
),
edited_posts AS (
    SELECT lasteditoruserid AS userid,
           COUNT(*) AS edited_post_count,
           SUM(score) AS edited_post_score
    FROM posts
    GROUP BY lasteditoruserid
),
posthistory_counts AS (
    SELECT userid,
           COUNT(*) AS posthistory_event_count
    FROM posthistory
    GROUP BY userid
),
posthistory_posts AS (
    SELECT ph.userid,
           COUNT(DISTINCT p.id) AS posthistory_related_post_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY ph.userid
)
SELECT u.id AS user_id,
       u.reputation,
       u.creationdate,
       u.views,
       u.upvotes,
       u.downvotes,
       COALESCE(bc.badge_count, 0) AS badge_count,
       COALESCE(op.owned_post_count, 0) AS owned_post_count,
       COALESCE(op.owned_post_score, 0) AS owned_post_score,
       COALESCE(op.avg_viewcount, 0) AS avg_viewcount,
       COALESCE(ep.edited_post_count, 0) AS edited_post_count,
       COALESCE(ep.edited_post_score, 0) AS edited_post_score,
       COALESCE(phc.posthistory_event_count, 0) AS posthistory_event_count,
       COALESCE(pht.posthistory_related_post_count, 0) AS posthistory_related_post_count
FROM users u
LEFT JOIN badge_counts bc ON bc.userid = u.id
LEFT JOIN owned_posts op ON op.userid = u.id
LEFT JOIN edited_posts ep ON ep.userid = u.id
LEFT JOIN posthistory_counts phc ON phc.userid = u.id
LEFT JOIN posthistory_posts pht ON pht.userid = u.id
ORDER BY u.reputation DESC
LIMIT 10
