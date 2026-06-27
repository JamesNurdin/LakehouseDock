WITH
    user_posts AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS post_count,
            COALESCE(SUM(p.score), 0) AS total_score,
            COALESCE(SUM(p.viewcount), 0) AS total_views,
            COALESCE(SUM(p.answercount), 0) AS total_answers,
            COALESCE(SUM(p.commentcount), 0) AS total_comments,
            COALESCE(SUM(p.favoritecount), 0) AS total_favorites
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            b.userid,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_votes_cast AS (
        SELECT
            v.userid,
            COUNT(*) AS votes_cast,
            COALESCE(SUM(v.bountyamount), 0) AS total_bounty_amount
        FROM votes v
        GROUP BY v.userid
    ),
    user_comments_made AS (
        SELECT
            c.userid,
            COUNT(*) AS comment_count
        FROM comments c
        GROUP BY c.userid
    ),
    user_post_votes_received AS (
        SELECT
            p.owneruserid,
            COUNT(v.id) AS votes_received,
            COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_received,
            COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_received
        FROM posts p
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_tags AS (
        SELECT
            p.owneruserid,
            COUNT(DISTINCT t.id) AS tag_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_edits AS (
        SELECT
            ph.userid,
            COUNT(*) AS edit_count
        FROM posthistory ph
        GROUP BY ph.userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_score, 0) AS total_score,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_comments, 0) AS total_comments,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.total_bounty_amount, 0) AS total_bounty_amount,
    COALESCE(ucm.comment_count, 0) AS comment_count,
    COALESCE(upv.votes_received, 0) AS votes_received,
    COALESCE(upv.upvotes_received, 0) AS upvotes_received,
    COALESCE(upv.downvotes_received, 0) AS downvotes_received,
    COALESCE(ut.tag_count, 0) AS tag_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    CASE
        WHEN COALESCE(up.post_count, 0) = 0 THEN 0
        ELSE COALESCE(up.total_score, 0) * 1.0 / COALESCE(up.post_count, 0)
    END AS avg_score_per_post
FROM users u
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_comments_made ucm ON ucm.userid = u.id
LEFT JOIN user_post_votes_received upv ON upv.owneruserid = u.id
LEFT JOIN user_tags ut ON ut.owneruserid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
ORDER BY u.reputation DESC
LIMIT 20
