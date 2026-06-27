WITH
    user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_count,
            SUM(p.score) AS total_post_score,
            AVG(p.score) AS avg_post_score,
            SUM(p.viewcount) AS total_views,
            SUM(p.favoritecount) AS total_favorites
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
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast
        FROM votes v
        GROUP BY v.userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS votes_received_count,
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_received,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_received
        FROM posts p
        JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            b.userid AS user_id,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_posthistory AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS posthistory_count
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS distinct_tag_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS postlink_count
        FROM posts p
        JOIN postlinks pl ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast,
    COALESCE(uvc.upvote_cast, 0) AS upvote_cast,
    COALESCE(uvc.downvote_cast, 0) AS downvote_cast,
    COALESCE(uvr.votes_received_count, 0) AS votes_received,
    COALESCE(uvr.upvote_received, 0) AS upvote_received,
    COALESCE(uvr.downvote_received, 0) AS downvote_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(up_link.postlink_count, 0) AS postlink_count,
    CASE
        WHEN COALESCE(up.total_views, 0) = 0 THEN NULL
        ELSE up.total_post_score / NULLIF(up.total_views, 0)
    END AS score_per_view
FROM users u
LEFT JOIN user_posts up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr ON uvr.user_id = u.id
LEFT JOIN user_badges ub ON ub.user_id = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_tags ut ON ut.user_id = u.id
LEFT JOIN user_postlinks up_link ON up_link.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 10
