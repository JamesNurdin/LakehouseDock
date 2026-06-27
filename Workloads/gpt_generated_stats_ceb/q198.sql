SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_views, 0) AS total_views,
    COALESCE(p.total_answers, 0) AS total_answers,
    COALESCE(p.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(p.total_favorites, 0) AS total_favorites,
    COALESCE(p.latest_post_date, TIMESTAMP '1970-01-01 00:00:00 UTC') AS latest_post_date,
    COALESCE(cm.comment_made_count, 0) AS comment_made_count,
    COALESCE(cm.comment_made_score, 0) AS comment_made_score,
    COALESCE(cr.comment_received_count, 0) AS comment_received_count,
    COALESCE(cr.comment_received_score, 0) AS comment_received_score,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(phm.posthistory_made_count, 0) AS posthistory_made_count,
    COALESCE(phr.posthistory_received_count, 0) AS posthistory_received_count,
    COALESCE(tg.tag_count, 0) AS tag_count,
    COALESCE(pe.posts_edited_count, 0) AS posts_edited_count
FROM users u
LEFT JOIN (
    SELECT owneruserid AS user_id,
           COUNT(*) AS post_count,
           SUM(score) AS total_post_score,
           SUM(viewcount) AS total_views,
           SUM(answercount) AS total_answers,
           SUM(commentcount) AS total_comments_on_posts,
           SUM(favoritecount) AS total_favorites,
           MAX(creationdate) AS latest_post_date
    FROM posts
    GROUP BY owneruserid
) p ON p.user_id = u.id
LEFT JOIN (
    SELECT userid AS user_id,
           COUNT(*) AS comment_made_count,
           SUM(score) AS comment_made_score
    FROM comments
    GROUP BY userid
) cm ON cm.user_id = u.id
LEFT JOIN (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS comment_received_count,
           SUM(c.score) AS comment_received_score
    FROM posts p
    JOIN comments c ON c.postid = p.id
    GROUP BY p.owneruserid
) cr ON cr.user_id = u.id
LEFT JOIN (
    SELECT userid AS user_id,
           COUNT(*) AS votes_cast_count,
           SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_cast,
           SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_cast
    FROM votes
    GROUP BY userid
) vc ON vc.user_id = u.id
LEFT JOIN (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS votes_received_count,
           SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
           SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
) vr ON vr.user_id = u.id
LEFT JOIN (
    SELECT userid AS user_id,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
) b ON b.user_id = u.id
LEFT JOIN (
    SELECT userid AS user_id,
           COUNT(*) AS posthistory_made_count
    FROM posthistory
    GROUP BY userid
) phm ON phm.user_id = u.id
LEFT JOIN (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS posthistory_received_count
    FROM posts p
    JOIN posthistory ph ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
) phr ON phr.user_id = u.id
LEFT JOIN (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
) tg ON tg.user_id = u.id
LEFT JOIN (
    SELECT lasteditoruserid AS user_id,
           COUNT(*) AS posts_edited_count
    FROM posts
    GROUP BY lasteditoruserid
) pe ON pe.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 100
