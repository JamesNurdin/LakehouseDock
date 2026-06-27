WITH badge_counts AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
post_counts AS (
    SELECT owneruserid AS userid,
           COUNT(*) AS post_count,
           SUM(score) AS total_score,
           AVG(score) AS avg_score,
           SUM(viewcount) AS total_views
    FROM posts
    GROUP BY owneruserid
),
edit_counts AS (
    SELECT lasteditoruserid AS userid,
           COUNT(*) AS edit_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
),
posthistory_counts AS (
    SELECT userid,
           COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
)
SELECT u.id,
       u.reputation,
       u.creationdate,
       u.views,
       u.upvotes,
       u.downvotes,
       COALESCE(bc.badge_count, 0)        AS badge_count,
       COALESCE(pc.post_count, 0)         AS post_count,
       COALESCE(pc.total_score, 0)        AS total_score,
       COALESCE(pc.avg_score, 0)          AS avg_score,
       COALESCE(pc.total_views, 0)        AS total_views,
       COALESCE(ec.edit_count, 0)         AS edit_count,
       COALESCE(phc.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN badge_counts bc ON bc.userid = u.id
LEFT JOIN post_counts pc ON pc.userid = u.id
LEFT JOIN edit_counts ec ON ec.userid = u.id
LEFT JOIN posthistory_counts phc ON phc.userid = u.id
ORDER BY total_score DESC
LIMIT 100
