WITH
    user_posts AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS post_count,
               SUM(p.score) AS total_post_score,
               AVG(p.score) AS avg_post_score,
               SUM(p.viewcount) AS total_views
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_comments AS (
        SELECT c.userid,
               COUNT(*) AS comment_count,
               SUM(c.score) AS total_comment_score,
               AVG(c.score) AS avg_comment_score
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes_cast AS (
        SELECT v.userid,
               COUNT(*) AS votes_cast_count,
               SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_cast,
               SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_cast
        FROM votes v
        GROUP BY v.userid
    ),
    user_votes_received AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS votes_received_count,
               SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
               SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT b.userid,
               COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_edits AS (
        SELECT p.lasteditoruserid AS userid,
               COUNT(*) AS edit_count
        FROM posts p
        GROUP BY p.lasteditoruserid
    ),
    user_posthistory AS (
        SELECT ph.userid,
               COUNT(*) AS posthistory_count
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    user_tags AS (
        SELECT p.owneruserid AS userid,
               COUNT(DISTINCT t.id) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks AS (
        SELECT p.owneruserid AS userid,
               COUNT(DISTINCT pl.id) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(up.post_count, 0) AS post_count,
       COALESCE(up.total_post_score, 0) AS total_post_score,
       COALESCE(up.avg_post_score, 0) AS avg_post_score,
       COALESCE(up.total_views, 0) AS total_views,
       COALESCE(uc.comment_count, 0) AS comment_count,
       COALESCE(uc.total_comment_score, 0) AS total_comment_score,
       COALESCE(uc.avg_comment_score, 0) AS avg_comment_score,
       COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
       COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
       COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
       COALESCE(vr.votes_received_count, 0) AS votes_received_count,
       COALESCE(vr.upvotes_received, 0) AS upvotes_received,
       COALESCE(vr.downvotes_received, 0) AS downvotes_received,
       COALESCE(bb.badge_count, 0) AS badge_count,
       COALESCE(ed.edit_count, 0) AS edit_count,
       COALESCE(ph.posthistory_count, 0) AS posthistory_count,
       COALESCE(tg.tag_count, 0) AS tag_count,
       COALESCE(pl.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN user_posts up          ON up.userid = u.id
LEFT JOIN user_comments uc       ON uc.userid = u.id
LEFT JOIN user_votes_cast vc     ON vc.userid = u.id
LEFT JOIN user_votes_received vr ON vr.userid = u.id
LEFT JOIN user_badges bb         ON bb.userid = u.id
LEFT JOIN user_edits ed          ON ed.userid = u.id
LEFT JOIN user_posthistory ph    ON ph.userid = u.id
LEFT JOIN user_tags tg           ON tg.userid = u.id
LEFT JOIN user_postlinks pl      ON pl.userid = u.id
ORDER BY total_post_score DESC
LIMIT 10
