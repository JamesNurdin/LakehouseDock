WITH
    user_posts AS (
        SELECT
            p.owneruserid AS owneruserid,
            COUNT(p.id) AS post_count,
            SUM(p.score) AS total_post_score,
            AVG(p.score) AS avg_post_score,
            SUM(p.viewcount) AS total_viewcount
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_comments AS (
        SELECT
            c.userid AS userid,
            COUNT(c.id) AS comment_count,
            SUM(c.score) AS total_comment_score,
            AVG(c.score) AS avg_comment_score
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes_cast AS (
        SELECT
            v.userid AS userid,
            COUNT(v.id) AS votes_cast_count,
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast_count,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast_count
        FROM votes v
        GROUP BY v.userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS owneruserid,
            COUNT(v.id) AS votes_received_count,
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_received_count,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_received_count,
            SUM(v.bountyamount) AS total_bounty_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            b.userid AS userid,
            COUNT(b.id) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_posthistory AS (
        SELECT
            ph.userid AS userid,
            COUNT(ph.id) AS posthistory_count
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS owneruserid,
            COUNT(t.id) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks AS (
        SELECT
            p.owneruserid AS owneruserid,
            COUNT(pl.id) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS total_posts,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(ucmt.comment_count, 0) AS total_comments,
    COALESCE(ucmt.total_comment_score, 0) AS total_comment_score,
    COALESCE(ucmt.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(uvc.votes_cast_count, 0) AS total_votes_cast,
    COALESCE(uvc.upvote_cast_count, 0) AS upvotes_cast,
    COALESCE(uvc.downvote_cast_count, 0) AS downvotes_cast,
    COALESCE(uvr.votes_received_count, 0) AS total_votes_received,
    COALESCE(uvr.upvote_received_count, 0) AS upvotes_received,
    COALESCE(uvr.downvote_received_count, 0) AS downvotes_received,
    COALESCE(uvr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(ub.badge_count, 0) AS total_badges,
    COALESCE(uph.posthistory_count, 0) AS total_posthistory_entries,
    COALESCE(utg.tag_count, 0) AS total_tags_on_posts,
    COALESCE(upl.postlink_count, 0) AS total_post_links
FROM users u
LEFT JOIN user_posts up       ON up.owneruserid   = u.id
LEFT JOIN user_comments ucmt  ON ucmt.userid      = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid       = u.id
LEFT JOIN user_votes_received uvr ON uvr.owneruserid = u.id
LEFT JOIN user_badges ub      ON ub.userid        = u.id
LEFT JOIN user_posthistory uph ON uph.userid      = u.id
LEFT JOIN user_tags utg       ON utg.owneruserid  = u.id
LEFT JOIN user_postlinks upl  ON upl.owneruserid  = u.id
ORDER BY u.reputation DESC
LIMIT 20
