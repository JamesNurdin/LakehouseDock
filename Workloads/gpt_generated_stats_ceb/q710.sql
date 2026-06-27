WITH post_metrics AS (
    SELECT owneruserid,
           COUNT(*) AS post_count,
           SUM(score) AS post_score_sum
    FROM posts
    GROUP BY owneruserid
),
comment_metrics AS (
    SELECT userid,
           COUNT(*) AS comment_count,
           SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
vote_metrics AS (
    SELECT userid,
           COUNT(*) AS vote_count,
           SUM(COALESCE(bountyamount, 0)) AS total_bounty
    FROM votes
    GROUP BY userid
),
badge_metrics AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
edit_metrics AS (
    SELECT lasteditoruserid,
           COUNT(*) AS edit_count
    FROM posts
    GROUP BY lasteditoruserid
),
tag_metrics AS (
    SELECT p.owneruserid,
           COUNT(DISTINCT t.id) AS tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.post_score_sum, 0) AS post_score_sum,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(cm.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(vm.vote_count, 0) AS vote_count,
    COALESCE(vm.total_bounty, 0) AS total_bounty,
    COALESCE(bm.badge_count, 0) AS badge_count,
    COALESCE(em.edit_count, 0) AS edit_count,
    COALESCE(tm.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN post_metrics pm ON pm.owneruserid = u.id
LEFT JOIN comment_metrics cm ON cm.userid = u.id
LEFT JOIN vote_metrics vm ON vm.userid = u.id
LEFT JOIN badge_metrics bm ON bm.userid = u.id
LEFT JOIN edit_metrics em ON em.lasteditoruserid = u.id
LEFT JOIN tag_metrics tm ON tm.owneruserid = u.id
ORDER BY pm.post_score_sum DESC NULLS LAST
LIMIT 100
