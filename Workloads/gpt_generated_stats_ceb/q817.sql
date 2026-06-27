WITH
    user_posts AS (
        SELECT owneruserid AS userid,
               COUNT(*) AS post_count,
               SUM(score) AS total_post_score,
               SUM(viewcount) AS total_viewcount,
               SUM(answercount) AS total_answercount,
               SUM(commentcount) AS total_commentcount,
               SUM(favoritecount) AS total_favoritecount
        FROM posts
        GROUP BY owneruserid
    ),
    votes_cast AS (
        SELECT userid,
               COUNT(*) AS votes_cast_count
        FROM votes
        GROUP BY userid
    ),
    votes_received AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS votes_received_count
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    comments_made AS (
        SELECT userid,
               COUNT(*) AS comments_made_count
        FROM comments
        GROUP BY userid
    ),
    comments_received AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS comments_received_count
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    badges_earned AS (
        SELECT userid,
               COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    post_history AS (
        SELECT userid,
               COUNT(*) AS post_history_count
        FROM posthistory
        GROUP BY userid
    ),
    tag_excerpts AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS tag_excerpt_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    CASE WHEN COALESCE(up.post_count, 0) > 0
        THEN CAST(COALESCE(up.total_post_score, 0) AS double) / COALESCE(up.post_count, 0)
        ELSE NULL
    END AS avg_post_score,
    COALESCE(up.total_viewcount, 0) AS total_viewcount,
    COALESCE(up.total_answercount, 0) AS total_answercount,
    COALESCE(up.total_commentcount, 0) AS total_commentcount,
    COALESCE(up.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(cm.comments_made_count, 0) AS comments_made_count,
    COALESCE(cr.comments_received_count, 0) AS comments_received_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.post_history_count, 0) AS post_history_count,
    COALESCE(te.tag_excerpt_count, 0) AS tag_excerpt_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN votes_cast vc ON vc.userid = u.id
LEFT JOIN votes_received vr ON vr.userid = u.id
LEFT JOIN comments_made cm ON cm.userid = u.id
LEFT JOIN comments_received cr ON cr.userid = u.id
LEFT JOIN badges_earned b ON b.userid = u.id
LEFT JOIN post_history ph ON ph.userid = u.id
LEFT JOIN tag_excerpts te ON te.userid = u.id
ORDER BY u.reputation DESC
LIMIT 20
