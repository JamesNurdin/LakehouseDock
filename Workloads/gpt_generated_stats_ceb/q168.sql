WITH
    user_posts AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS post_count,
            COALESCE(SUM(p.score), 0) AS total_post_score,
            COALESCE(SUM(p.viewcount), 0) AS total_views,
            COALESCE(SUM(p.favoritecount), 0) AS total_favorites,
            COALESCE(SUM(p.answercount), 0) AS total_answers
        FROM posts p
        GROUP BY p.owneruserid
    ),
    user_comments_made AS (
        SELECT
            c.userid AS userid,
            COUNT(*) AS comment_made_count
        FROM comments c
        GROUP BY c.userid
    ),
    user_comments_received AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(c.id) AS comment_received_count
        FROM posts p
        LEFT JOIN comments c ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_votes_cast AS (
        SELECT
            v.userid AS userid,
            COUNT(*) AS votes_cast
        FROM votes v
        GROUP BY v.userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(v.id) AS votes_received_count,
            COALESCE(SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END), 0) AS upvotes_received,
            COALESCE(SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END), 0) AS downvotes_received
        FROM posts p
        LEFT JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            b.userid AS userid,
            COUNT(*) AS badge_count
        FROM badges b
        GROUP BY b.userid
    ),
    user_tag_usage AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(t.id) AS tag_count
        FROM posts p
        LEFT JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    up.post_count,
    up.total_post_score,
    up.total_views,
    up.total_favorites,
    up.total_answers,
    uc.comment_made_count,
    ur.comment_received_count,
    vc.votes_cast,
    vr.votes_received_count,
    vr.upvotes_received,
    vr.downvotes_received,
    b.badge_count,
    tu.tag_count
FROM users u
LEFT JOIN user_posts up ON up.userid = u.id
LEFT JOIN user_comments_made uc ON uc.userid = u.id
LEFT JOIN user_comments_received ur ON ur.userid = u.id
LEFT JOIN user_votes_cast vc ON vc.userid = u.id
LEFT JOIN user_votes_received vr ON vr.userid = u.id
LEFT JOIN user_badges b ON b.userid = u.id
LEFT JOIN user_tag_usage tu ON tu.userid = u.id
ORDER BY up.total_post_score DESC
LIMIT 10
