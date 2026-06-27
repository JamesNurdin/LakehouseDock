WITH
    user_base AS (
        SELECT u.id AS userid,
               u.reputation
        FROM users u
    ),
    posts_owned AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS posts_owned,
               SUM(p.score) AS total_post_score,
               SUM(p.viewcount) AS total_viewcount,
               AVG(p.answercount) AS avg_answercount,
               SUM(p.favoritecount) AS total_favoritecount
        FROM posts p
        GROUP BY p.owneruserid
    ),
    posts_edited AS (
        SELECT p.lasteditoruserid AS userid,
               COUNT(*) AS posts_edited
        FROM posts p
        GROUP BY p.lasteditoruserid
    ),
    comments_made AS (
        SELECT c.userid AS userid,
               COUNT(*) AS comments_made
        FROM comments c
        GROUP BY c.userid
    ),
    votes_cast AS (
        SELECT v.userid AS userid,
               COUNT(*) AS votes_cast
        FROM votes v
        GROUP BY v.userid
    ),
    votes_received AS (
        SELECT p.owneruserid AS userid,
               COUNT(*) AS votes_received
        FROM votes v
        JOIN posts p ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    badges_earned AS (
        SELECT b.userid AS userid,
               COUNT(*) AS badges_earned
        FROM badges b
        GROUP BY b.userid
    ),
    distinct_tags AS (
        SELECT p.owneruserid AS userid,
               COUNT(DISTINCT t.id) AS distinct_tags
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    posthistory_counts AS (
        SELECT ph.userid AS userid,
               COUNT(*) AS post_history_entries
        FROM posthistory ph
        GROUP BY ph.userid
    )
SELECT
    ub.userid,
    ub.reputation,
    COALESCE(po.posts_owned, 0) AS posts_owned,
    COALESCE(po.total_post_score, 0) AS total_post_score,
    COALESCE(po.total_viewcount, 0) AS total_viewcount,
    COALESCE(po.avg_answercount, 0) AS avg_answercount,
    COALESCE(po.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(pe.posts_edited, 0) AS posts_edited,
    COALESCE(cm.comments_made, 0) AS comments_made,
    COALESCE(vc.votes_cast, 0) AS votes_cast,
    COALESCE(vr.votes_received, 0) AS votes_received,
    COALESCE(be.badges_earned, 0) AS badges_earned,
    COALESCE(dt.distinct_tags, 0) AS distinct_tags,
    COALESCE(phc.post_history_entries, 0) AS post_history_entries
FROM user_base ub
LEFT JOIN posts_owned po ON ub.userid = po.userid
LEFT JOIN posts_edited pe ON ub.userid = pe.userid
LEFT JOIN comments_made cm ON ub.userid = cm.userid
LEFT JOIN votes_cast vc ON ub.userid = vc.userid
LEFT JOIN votes_received vr ON ub.userid = vr.userid
LEFT JOIN badges_earned be ON ub.userid = be.userid
LEFT JOIN distinct_tags dt ON ub.userid = dt.userid
LEFT JOIN posthistory_counts phc ON ub.userid = phc.userid
ORDER BY ub.reputation DESC, posts_owned DESC
LIMIT 100
