WITH
    badges_per_user AS (
        SELECT userid,
               COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    posts_per_user AS (
        SELECT owneruserid AS userid,
               COUNT(*) AS post_count,
               SUM(score) AS total_post_score,
               SUM(viewcount) AS total_views
        FROM posts
        GROUP BY owneruserid
    ),
    comments_per_user AS (
        SELECT userid,
               COUNT(*) AS comment_count,
               AVG(score) AS avg_comment_score,
               SUM(score) AS total_comment_score
        FROM comments
        GROUP BY userid
    ),
    votes_cast_per_user AS (
        SELECT userid,
               COUNT(*) AS votes_cast,
               SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS up_votes_cast,
               SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS down_votes_cast
        FROM votes
        GROUP BY userid
    ),
    votes_received_per_user AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS votes_received,
               SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS up_votes_received,
               SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS down_votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    edits_per_user AS (
        SELECT lasteditoruserid AS userid,
               COUNT(*) AS edit_count
        FROM posts
        GROUP BY lasteditoruserid
    ),
    tags_per_user AS (
        SELECT p.owneruserid AS userid,
               COUNT(DISTINCT t.id) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    posthistory_per_user AS (
        SELECT userid,
               COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    source_links_per_user AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS source_link_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    target_links_per_user AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS target_link_count
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_views, 0) AS total_views,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vc.up_votes_cast, 0) AS up_votes_cast,
    COALESCE(vc.down_votes_cast, 0) AS down_votes_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(vr.up_votes_received, 0) AS up_votes_received,
    COALESCE(vr.down_votes_received, 0) AS down_votes_received,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(t.tag_count, 0) AS tag_count,
    COALESCE(ph.posthistory_count, 0) AS posthistory_count,
    COALESCE(sl.source_link_count, 0) AS source_link_count,
    COALESCE(tl.target_link_count, 0) AS target_link_count
FROM users u
LEFT JOIN badges_per_user b ON b.userid = u.id
LEFT JOIN posts_per_user p ON p.userid = u.id
LEFT JOIN comments_per_user c ON c.userid = u.id
LEFT JOIN votes_cast_per_user vc ON vc.userid = u.id
LEFT JOIN votes_received_per_user vr ON vr.userid = u.id
LEFT JOIN edits_per_user e ON e.userid = u.id
LEFT JOIN tags_per_user t ON t.userid = u.id
LEFT JOIN posthistory_per_user ph ON ph.userid = u.id
LEFT JOIN source_links_per_user sl ON sl.userid = u.id
LEFT JOIN target_links_per_user tl ON tl.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
