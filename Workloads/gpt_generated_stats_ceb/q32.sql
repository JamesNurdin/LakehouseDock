WITH
    user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS posts_owned,
            AVG(p.score) AS avg_post_score
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_edits AS (
        SELECT
            p.lasteditoruserid AS user_id,
            COUNT(*) AS posts_edited
        FROM posts p
        GROUP BY p.lasteditoruserid
    ),
    user_comments_made AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comments_made,
            AVG(c.score) AS avg_comment_score_made
        FROM comments c
        GROUP BY c.userid
    ),
    user_comments_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS comments_received
        FROM comments c
        JOIN posts p
            ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_outgoing_links AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS outgoing_links
        FROM postlinks pl
        JOIN posts p
            ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_incoming_links AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS incoming_links
        FROM postlinks pl
        JOIN posts p
            ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.posts_owned, 0) AS posts_owned,
    COALESCE(ue.posts_edited, 0) AS posts_edited,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(ucm.comments_made, 0) AS comments_made,
    COALESCE(ucm.avg_comment_score_made, 0) AS avg_comment_score_made,
    COALESCE(ucr.comments_received, 0) AS comments_received,
    COALESCE(uol.outgoing_links, 0) AS outgoing_links,
    COALESCE(uil.incoming_links, 0) AS incoming_links,
    (
        COALESCE(up.posts_owned, 0) +
        COALESCE(ue.posts_edited, 0) +
        COALESCE(ucm.comments_made, 0) +
        COALESCE(ucr.comments_received, 0) +
        COALESCE(uol.outgoing_links, 0) +
        COALESCE(uil.incoming_links, 0)
    ) AS total_activity
FROM users u
LEFT JOIN user_posts up
    ON up.user_id = u.id
LEFT JOIN user_edits ue
    ON ue.user_id = u.id
LEFT JOIN user_comments_made ucm
    ON ucm.user_id = u.id
LEFT JOIN user_comments_received ucr
    ON ucr.user_id = u.id
LEFT JOIN user_outgoing_links uol
    ON uol.user_id = u.id
LEFT JOIN user_incoming_links uil
    ON uil.user_id = u.id
ORDER BY total_activity DESC
LIMIT 100
