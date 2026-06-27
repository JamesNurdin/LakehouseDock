SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.total_post_score, 0) AS total_post_score,
    pm.avg_post_score,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(vm.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(vm.upvote_cast, 0) AS upvote_cast,
    COALESCE(vm.downvote_cast, 0) AS downvote_cast,
    COALESCE(bm.badge_count, 0) AS badge_count,
    COALESCE(phm.post_edit_count, 0) AS post_edit_count,
    COALESCE(plm.postlink_count, 0) AS postlink_count,
    COALESCE(tm.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN (
    SELECT owneruserid AS userid,
           COUNT(*) AS post_count,
           SUM(score) AS total_post_score,
           AVG(score) AS avg_post_score
    FROM posts
    GROUP BY owneruserid
) pm ON pm.userid = u.id
LEFT JOIN (
    SELECT userid,
           COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
) cm ON cm.userid = u.id
LEFT JOIN (
    SELECT userid,
           COUNT(*) AS vote_cast_count,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cast,
           SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cast
    FROM votes
    GROUP BY userid
) vm ON vm.userid = u.id
LEFT JOIN (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
) bm ON bm.userid = u.id
LEFT JOIN (
    SELECT userid,
           COUNT(*) AS post_edit_count
    FROM posthistory
    GROUP BY userid
) phm ON phm.userid = u.id
LEFT JOIN (
    SELECT p.owneruserid AS userid,
           COUNT(DISTINCT pl.id) AS postlink_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
) plm ON plm.userid = u.id
LEFT JOIN (
    SELECT p.owneruserid AS userid,
           COUNT(DISTINCT t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
) tm ON tm.userid = u.id
ORDER BY total_post_score DESC
LIMIT 20
