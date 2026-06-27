WITH
    user_base AS (
        SELECT
            id,
            reputation,
            creationdate,
            views,
            upvotes,
            downvotes
        FROM users
    ),
    user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(p.score) AS total_post_score,
            SUM(p.viewcount) AS total_viewcount,
            SUM(p.answercount) AS total_answercount,
            SUM(p.commentcount) AS total_commentcount,
            SUM(p.favoritecount) AS total_favoritecount
        FROM posts p
        JOIN user_base u ON p.owneruserid = u.id
        GROUP BY p.owneruserid
    ),
    user_edited_posts AS (
        SELECT
            p.lasteditoruserid AS user_id,
            COUNT(*) AS edited_post_count,
            SUM(p.score) AS edited_total_score
        FROM posts p
        JOIN user_base u ON p.lasteditoruserid = u.id
        GROUP BY p.lasteditoruserid
    ),
    user_comments AS (
        SELECT
            c.userid AS user_id,
            COUNT(*) AS comment_count,
            SUM(c.score) AS total_comment_score
        FROM comments c
        JOIN user_base u ON c.userid = u.id
        GROUP BY c.userid
    ),
    user_votes_cast AS (
        SELECT
            v.userid AS user_id,
            COUNT(*) AS votes_cast_count,
            COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvote_cast_count,
            COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvote_cast_count,
            SUM(v.bountyamount) AS total_bounty_given
        FROM votes v
        JOIN user_base u ON v.userid = u.id
        GROUP BY v.userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received_count,
            COUNT(CASE WHEN v.votetypeid = 1 THEN 1 END) AS upvote_received_count,
            COUNT(CASE WHEN v.votetypeid = 2 THEN 1 END) AS downvote_received_count,
            SUM(v.bountyamount) AS total_bounty_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        JOIN user_base u ON p.owneruserid = u.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges b
        JOIN user_base u ON b.userid = u.id
        GROUP BY b.userid
    ),
    user_posthistory AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS posthistory_count
        FROM posthistory ph
        JOIN user_base u ON ph.userid = u.id
        GROUP BY ph.userid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS tag_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        JOIN user_base u ON p.owneruserid = u.id
        GROUP BY p.owneruserid
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
    COALESCE(ue.edited_post_count, 0) AS edited_post_count,
    COALESCE(ue.edited_total_score, 0) AS edited_total_score,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvc.upvote_cast_count, 0) AS upvote_cast_count,
    COALESCE(uvc.downvote_cast_count, 0) AS downvote_cast_count,
    COALESCE(uvc.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(uvr.votes_received_count, 0) AS votes_received_count,
    COALESCE(uvr.upvote_received_count, 0) AS upvote_received_count,
    COALESCE(uvr.downvote_received_count, 0) AS downvote_received_count,
    COALESCE(uvr.total_bounty_received, 0) AS total_bounty_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ut.tag_count, 0) AS tag_count
FROM user_base u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_edited_posts ue ON ue.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
