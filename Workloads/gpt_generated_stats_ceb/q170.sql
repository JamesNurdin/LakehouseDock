WITH post_metrics AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS post_count,
           SUM(score) AS total_score,
           AVG(score) AS avg_score,
           SUM(viewcount) AS total_views
    FROM posts
    GROUP BY owneruserid
),

tag_counts AS (
    SELECT p.owneruserid AS user_id,
           COUNT(DISTINCT t.id) AS tag_count
    FROM posts p
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),

edit_counts AS (
    SELECT lasteditoruserid AS user_id,
           COUNT(*) AS edit_count
    FROM posts
    WHERE lasteditoruserid IS NOT NULL
    GROUP BY lasteditoruserid
),

comment_metrics AS (
    SELECT userid AS user_id,
           COUNT(*) AS comment_count,
           AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY userid
),

vote_metrics AS (
    SELECT userid AS user_id,
           COUNT(*) AS vote_count,
           SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast
    FROM votes
    GROUP BY userid
),

badge_counts AS (
    SELECT userid AS user_id,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),

posthistory_counts AS (
    SELECT userid AS user_id,
           COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
)

SELECT u.id,
       u.reputation,
       COALESCE(pm.post_count, 0) AS post_count,
       COALESCE(pm.total_score, 0) AS total_score,
       COALESCE(pm.avg_score, 0) AS avg_score,
       COALESCE(pm.total_views, 0) AS total_views,
       COALESCE(tc.tag_count, 0) AS tag_count,
       COALESCE(ec.edit_count, 0) AS edit_count,
       COALESCE(cm.comment_count, 0) AS comment_count,
       COALESCE(cm.avg_comment_score, 0) AS avg_comment_score,
       COALESCE(vm.vote_count, 0) AS vote_count,
       COALESCE(vm.upvote_cast, 0) AS upvote_cast,
       COALESCE(vm.downvote_cast, 0) AS downvote_cast,
       COALESCE(bc.badge_count, 0) AS badge_count,
       COALESCE(phc.posthistory_count, 0) AS posthistory_count
FROM users u
LEFT JOIN post_metrics pm ON pm.user_id = u.id
LEFT JOIN tag_counts tc ON tc.user_id = u.id
LEFT JOIN edit_counts ec ON ec.user_id = u.id
LEFT JOIN comment_metrics cm ON cm.user_id = u.id
LEFT JOIN vote_metrics vm ON vm.user_id = u.id
LEFT JOIN badge_counts bc ON bc.user_id = u.id
LEFT JOIN posthistory_counts phc ON phc.user_id = u.id
ORDER BY post_count DESC, total_score DESC
LIMIT 100
