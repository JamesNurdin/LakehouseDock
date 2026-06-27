WITH owner_posts AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_post_score,
        SUM(p.viewcount) AS total_viewcount,
        SUM(p.answercount) AS total_answercount,
        SUM(p.commentcount) AS total_post_comment_count,
        SUM(p.favoritecount) AS total_favoritecount
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid,
        COUNT(*) AS comment_count,
        SUM(c.score) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
user_votes_cast AS (
    SELECT
        v.userid,
        COUNT(*) AS votes_cast_count,
        SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_cast
    FROM votes v
    GROUP BY v.userid
),
votes_received AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS votes_received_count,
        SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_received
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_tags AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
user_postlinks_out AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS outgoing_link_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
user_postlinks_in AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS incoming_link_count
    FROM postlinks pl
    JOIN posts p ON pl.relatedpostid = p.id
    GROUP BY p.owneruserid
),
user_posthistory AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(*) AS posthistory_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
),
user_edits AS (
    SELECT
        p.lasteditoruserid AS userid,
        COUNT(*) AS edit_count
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
)
SELECT
    u.id,
    u.reputation,
    u.creationdate,
    COALESCE(op.post_count, 0) AS post_count,
    COALESCE(op.total_post_score, 0) AS total_post_score,
    COALESCE(op.total_viewcount, 0) AS total_viewcount,
    COALESCE(op.total_answercount, 0) AS total_answercount,
    COALESCE(op.total_post_comment_count, 0) AS total_post_comment_count,
    COALESCE(op.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vc.total_bounty_cast, 0) AS total_bounty_cast,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(vr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(upo.outgoing_link_count, 0) AS outgoing_link_count,
    COALESCE(upi.incoming_link_count, 0) AS incoming_link_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ue.edit_count, 0) AS edit_count
FROM users u
LEFT JOIN owner_posts op ON u.id = op.userid
LEFT JOIN user_comments uc ON u.id = uc.userid
LEFT JOIN user_votes_cast vc ON u.id = vc.userid
LEFT JOIN votes_received vr ON u.id = vr.userid
LEFT JOIN user_tags ut ON u.id = ut.userid
LEFT JOIN user_postlinks_out upo ON u.id = upo.userid
LEFT JOIN user_postlinks_in upi ON u.id = upi.userid
LEFT JOIN user_posthistory uph ON u.id = uph.userid
LEFT JOIN user_edits ue ON u.id = ue.userid
ORDER BY (total_post_score + total_comment_score + total_bounty_received) DESC
LIMIT 10
