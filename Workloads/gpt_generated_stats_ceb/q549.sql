WITH
    user_posts AS (
        SELECT
            owneruserid AS userid,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            SUM(viewcount) AS total_views,
            SUM(answercount) AS total_answers,
            SUM(commentcount) AS total_comments_on_posts,
            SUM(favoritecount) AS total_favorites
        FROM posts
        GROUP BY owneruserid
    ),
    user_edits AS (
        SELECT
            lasteditoruserid AS userid,
            COUNT(*) AS edit_count
        FROM posts
        GROUP BY lasteditoruserid
    ),
    user_comments AS (
        SELECT
            userid,
            COUNT(*) AS comment_count,
            SUM(score) AS comment_score_sum
        FROM comments
        GROUP BY userid
    ),
    user_votes_cast AS (
        SELECT
            userid,
            COUNT(*) AS votes_cast,
            SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_cast,
            SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_cast
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS votes_received,
            SUM(CASE WHEN v.votetypeid = 1 THEN 1 ELSE 0 END) AS upvotes_received,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS downvotes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_posthistory AS (
        SELECT
            userid,
            COUNT(*) AS posthistory_count
        FROM posthistory
        GROUP BY userid
    ),
    user_posthistory_on_posts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS posthistory_on_posts
        FROM posthistory ph
        JOIN posts p ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
        UNION ALL
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks_agg AS (
        SELECT
            userid,
            SUM(postlink_count) AS total_postlinks
        FROM user_postlinks
        GROUP BY userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    CASE WHEN COALESCE(up.post_count, 0) = 0 THEN 0
         ELSE COALESCE(up.total_post_score, 0) / COALESCE(up.post_count, 0) END AS avg_post_score,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_comments_on_posts, 0) AS total_comments_on_posts,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(uvc.votes_cast, 0) AS votes_cast,
    COALESCE(uvc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(uvc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(uvr.votes_received, 0) AS votes_received,
    COALESCE(uvr.upvotes_received, 0) AS upvotes_received,
    COALESCE(uvr.downvotes_received, 0) AS downvotes_received,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(upho.posthistory_on_posts, 0) AS posthistory_on_posts,
    COALESCE(upla.total_postlinks, 0) AS total_postlinks
FROM users u
LEFT JOIN user_posts up ON u.id = up.userid
LEFT JOIN user_edits ue ON u.id = ue.userid
LEFT JOIN user_comments uc ON u.id = uc.userid
LEFT JOIN user_votes_cast uvc ON u.id = uvc.userid
LEFT JOIN user_votes_received uvr ON u.id = uvr.userid
LEFT JOIN user_badges ub ON u.id = ub.userid
LEFT JOIN user_posthistory uph ON u.id = uph.userid
LEFT JOIN user_posthistory_on_posts upho ON u.id = upho.userid
LEFT JOIN user_postlinks_agg upla ON u.id = upla.userid
WHERE u.reputation > 1000
ORDER BY total_postlinks DESC, post_count DESC
LIMIT 100
