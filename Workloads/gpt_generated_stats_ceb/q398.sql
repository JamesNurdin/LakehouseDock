SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.post_count, 0)               AS post_count,
    COALESCE(p.total_viewcount, 0)          AS total_viewcount,
    COALESCE(p.avg_post_score, 0)           AS avg_post_score,
    COALESCE(cm.comment_made_count, 0)      AS comment_made_count,
    COALESCE(cm.comment_made_score_sum, 0) AS comment_made_score_sum,
    COALESCE(cr.comment_received_count, 0) AS comment_received_count,
    COALESCE(vc.votes_cast_count, 0)        AS votes_cast_count,
    COALESCE(vc.total_bounty_cast, 0)       AS total_bounty_cast,
    COALESCE(vr.votes_received_count, 0)    AS votes_received_count,
    COALESCE(vr.total_bounty_received, 0)   AS total_bounty_received,
    COALESCE(b.badge_count, 0)              AS badge_count,
    COALESCE(t.tag_excerpt_count, 0)        AS tag_excerpt_count,
    COALESCE(pl_out.postlink_outgoing_count, 0)  AS postlink_outgoing_count,
    COALESCE(pl_in.postlink_incoming_count, 0)   AS postlink_incoming_count,
    COALESCE(ph_act.posthistory_action_count, 0) AS posthistory_action_count,
    COALESCE(ph_type.posthistory_type_match_count, 0) AS posthistory_type_match_count
FROM users u
LEFT JOIN (
    SELECT owneruserid,
           COUNT(*)               AS post_count,
           SUM(viewcount)         AS total_viewcount,
           AVG(score)             AS avg_post_score
    FROM posts
    GROUP BY owneruserid
) p ON p.owneruserid = u.id
LEFT JOIN (
    SELECT userid,
           COUNT(*)               AS comment_made_count,
           SUM(score)             AS comment_made_score_sum
    FROM comments
    GROUP BY userid
) cm ON cm.userid = u.id
LEFT JOIN (
    SELECT p.owneruserid,
           COUNT(*)               AS comment_received_count
    FROM posts p
    JOIN comments c ON c.postid = p.id
    GROUP BY p.owneruserid
) cr ON cr.owneruserid = u.id
LEFT JOIN (
    SELECT userid,
           COUNT(*)               AS votes_cast_count,
           SUM(bountyamount)      AS total_bounty_cast
    FROM votes
    GROUP BY userid
) vc ON vc.userid = u.id
LEFT JOIN (
    SELECT p.owneruserid,
           COUNT(*)               AS votes_received_count,
           SUM(v.bountyamount)    AS total_bounty_received
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
) vr ON vr.owneruserid = u.id
LEFT JOIN (
    SELECT userid,
           COUNT(*)               AS badge_count
    FROM badges
    GROUP BY userid
) b ON b.userid = u.id
LEFT JOIN (
    SELECT p.owneruserid,
           COUNT(*)               AS tag_excerpt_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
) t ON t.owneruserid = u.id
LEFT JOIN (
    SELECT p.owneruserid,
           COUNT(*)               AS postlink_outgoing_count
    FROM posts p
    JOIN postlinks pl ON pl.postid = p.id
    GROUP BY p.owneruserid
) pl_out ON pl_out.owneruserid = u.id
LEFT JOIN (
    SELECT p.owneruserid,
           COUNT(*)               AS postlink_incoming_count
    FROM posts p
    JOIN postlinks pl ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
) pl_in ON pl_in.owneruserid = u.id
LEFT JOIN (
    SELECT userid,
           COUNT(*)               AS posthistory_action_count
    FROM posthistory
    GROUP BY userid
) ph_act ON ph_act.userid = u.id
LEFT JOIN (
    SELECT p.owneruserid,
           COUNT(*)               AS posthistory_type_match_count
    FROM posts p
    JOIN posthistory ph ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
) ph_type ON ph_type.owneruserid = u.id
ORDER BY u.reputation DESC
LIMIT 100
