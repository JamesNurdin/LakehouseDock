WITH
    user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(p.score) AS post_score_sum,
            AVG(p.score) AS post_score_avg
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_edits AS (
        SELECT
            p.lasteditoruserid AS user_id,
            COUNT(*) AS edit_count
        FROM posts p
        GROUP BY p.lasteditoruserid
    ),
    user_comments AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comment_count,
            SUM(c.score) AS comment_score_sum
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes_cast AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS votes_cast_count,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
        FROM votes v
        GROUP BY v.userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received_count,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_comments_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS comments_received_count
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    post_outgoing_links AS (
        SELECT
            pl.postid AS post_id,
            COUNT(*) AS outgoing_link_count
        FROM postlinks pl
        GROUP BY pl.postid
    ),
    post_incoming_links AS (
        SELECT
            pl.relatedpostid AS post_id,
            COUNT(*) AS incoming_link_count
        FROM postlinks pl
        GROUP BY pl.relatedpostid
    ),
    user_post_links AS (
        SELECT
            p.owneruserid AS user_id,
            SUM(COALESCE(o.outgoing_link_count, 0) + COALESCE(i.incoming_link_count, 0)) AS total_links_on_posts
        FROM posts p
        LEFT JOIN post_outgoing_links o ON p.id = o.post_id
        LEFT JOIN post_incoming_links i ON p.id = i.post_id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_score_avg, 0) AS post_score_avg,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(uvc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
    COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
    COALESCE(ucr.comments_received_count, 0) AS comments_received_count,
    COALESCE(upL.total_links_on_posts, 0) AS total_links_on_posts
FROM users u
LEFT JOIN user_posts up ON u.id = up.user_id
LEFT JOIN user_edits ue ON u.id = ue.user_id
LEFT JOIN user_comments uc ON u.id = uc.user_id
LEFT JOIN user_votes_cast uvc ON u.id = uvc.user_id
LEFT JOIN user_votes_received uvr ON u.id = uvr.user_id
LEFT JOIN user_comments_received ucr ON u.id = ucr.user_id
LEFT JOIN user_post_links upL ON u.id = upL.user_id
ORDER BY post_score_sum DESC
LIMIT 100
