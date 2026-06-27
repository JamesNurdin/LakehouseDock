WITH
    user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(p.score) AS total_post_score,
            SUM(p.viewcount) AS total_viewcount,
            SUM(p.favoritecount) AS total_favoritecount,
            SUM(p.answercount) AS total_answercount
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_comments AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comment_count,
            SUM(c.score) AS total_comment_score
        FROM comments c
        GROUP BY c.userid
    ),
    user_votes_cast AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS votes_cast_count,
            SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_amount
        FROM votes v
        GROUP BY v.userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received_count
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_edits AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS edit_count
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS distinct_tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_outgoing_links AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS outgoing_link_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_incoming_links AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS incoming_link_count
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_posthistory_by_type AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS posthistory_type_count
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0)               AS post_count,
    COALESCE(up.total_post_score, 0)         AS total_post_score,
    COALESCE(up.total_viewcount, 0)          AS total_viewcount,
    COALESCE(up.total_favoritecount, 0)      AS total_favoritecount,
    COALESCE(up.total_answercount, 0)        AS total_answercount,
    COALESCE(uc.comment_count, 0)            AS comment_count,
    COALESCE(uc.total_comment_score, 0)      AS total_comment_score,
    COALESCE(uvc.votes_cast_count, 0)        AS votes_cast_count,
    COALESCE(uvc.total_bounty_amount, 0)     AS total_bounty_amount,
    COALESCE(uvr.votes_received_count, 0)    AS votes_received_count,
    COALESCE(ub.badge_count, 0)              AS badge_count,
    COALESCE(ue.edit_count, 0)               AS edit_count,
    COALESCE(ut.distinct_tag_count, 0)       AS distinct_tag_count,
    COALESCE(ul.outgoing_link_count, 0)      AS outgoing_link_count,
    COALESCE(ui.incoming_link_count, 0)      AS incoming_link_count,
    COALESCE(upt.posthistory_type_count, 0)  AS posthistory_type_count,
    RANK() OVER (ORDER BY COALESCE(up.total_post_score, 0) DESC) AS score_rank
FROM users u
LEFT JOIN user_posts up               ON up.user_id = u.id
LEFT JOIN user_comments uc            ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc         ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr    ON uvr.user_id = u.id
LEFT JOIN user_badges ub              ON ub.user_id = u.id
LEFT JOIN user_edits ue               ON ue.user_id = u.id
LEFT JOIN user_tags ut                ON ut.user_id = u.id
LEFT JOIN user_outgoing_links ul      ON ul.user_id = u.id
LEFT JOIN user_incoming_links ui      ON ui.user_id = u.id
LEFT JOIN user_posthistory_by_type upt ON upt.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 10
