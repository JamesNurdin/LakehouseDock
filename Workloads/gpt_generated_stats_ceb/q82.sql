WITH
    user_posts AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS post_count,
            SUM(p.score) AS total_post_score,
            SUM(p.viewcount) AS total_viewcount,
            SUM(p.answercount) AS total_answercount,
            SUM(p.commentcount) AS total_commentcount,
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
            SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_given
        FROM votes v
        GROUP BY v.userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid,
            COUNT(v.id) AS votes_received_count,
            SUM(COALESCE(v.bountyamount, 0)) AS total_bounty_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            b.userid,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_edits AS (
        SELECT
            p.lasteditoruserid,
            COUNT(*) AS edit_count
        FROM posts p
        WHERE p.lasteditoruserid IS NOT NULL
        GROUP BY p.lasteditoruserid
    ),
    user_history AS (
        SELECT
            ph.userid,
            COUNT(*) AS posthistory_count
        FROM posthistory ph
        GROUP BY ph.userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_answercount, 0) AS total_answercount,
    COALESCE(up.total_commentcount, 0) AS total_commentcount,
    COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vc.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(vr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uh.posthistory_count, 0) AS posthistory_count,
    CASE WHEN COALESCE(up.post_count, 0) = 0 THEN 0
         ELSE COALESCE(up.total_post_score, 0) * 1.0 / up.post_count END AS avg_post_score,
    CASE WHEN COALESCE(uc.comment_count, 0) = 0 THEN 0
         ELSE COALESCE(uc.total_comment_score, 0) * 1.0 / uc.comment_count END AS avg_comment_score
FROM users u
LEFT JOIN user_posts up ON u.id = up.owneruserid
LEFT JOIN user_comments uc ON u.id = uc.userid
LEFT JOIN user_votes_cast vc ON u.id = vc.userid
LEFT JOIN user_votes_received vr ON u.id = vr.owneruserid
LEFT JOIN user_badges ub ON u.id = ub.userid
LEFT JOIN user_edits ue ON u.id = ue.lasteditoruserid
LEFT JOIN user_history uh ON u.id = uh.userid
ORDER BY u.reputation DESC
LIMIT 100
