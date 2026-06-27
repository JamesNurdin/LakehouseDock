WITH
    user_posts AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS post_count,
            SUM(p.score) AS total_post_score
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_comments AS (
        SELECT
            c.userid,
            COUNT(*) AS comment_count
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes_cast AS (
        SELECT
            v.userid,
            COUNT(*) AS votes_cast
        FROM votes v
        GROUP BY v.userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_edits_made AS (
        SELECT
            ph.userid,
            COUNT(*) AS edits_made
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    user_last_edits AS (
        SELECT
            p.lasteditoruserid,
            COUNT(*) AS last_edits
        FROM posts p
        WHERE p.lasteditoruserid IS NOT NULL
        GROUP BY p.lasteditoruserid
    ),
    user_posthistory_on_posts AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS posthistory_on_posts_count
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uem.edits_made, 0) AS edits_made,
    COALESCE(ule.last_edits, 0) AS last_edits,
    COALESCE(uphp.posthistory_on_posts_count, 0) AS posthistory_on_posts_count
FROM users u
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvr ON uvr.owneruserid = u.id
LEFT JOIN user_edits_made uem ON uem.userid = u.id
LEFT JOIN user_last_edits ule ON ule.lasteditoruserid = u.id
LEFT JOIN user_posthistory_on_posts uphp ON uphp.owneruserid = u.id
ORDER BY total_post_score DESC
LIMIT 20
