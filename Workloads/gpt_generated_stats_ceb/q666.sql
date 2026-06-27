WITH
    user_posts AS (
        SELECT
            u.id AS user_id,
            COUNT(p.id) AS post_count,
            SUM(p.score) AS post_score_sum,
            AVG(p.score) AS post_score_avg,
            SUM(p.viewcount) AS total_views,
            SUM(p.favoritecount) AS total_favorites
        FROM users u
        JOIN posts p ON p.owneruserid = u.id
        GROUP BY u.id
    ),
    user_comments AS (
        SELECT
            u.id AS user_id,
            COUNT(c.id) AS comment_count,
            SUM(c.score) AS comment_score_sum
        FROM users u
        JOIN comments c ON c.userid = u.id
        GROUP BY u.id
    ),
    user_votes_cast AS (
        SELECT
            u.id AS user_id,
            COUNT(v.id) AS votes_cast_count,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_cast,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_cast
        FROM users u
        JOIN votes v ON v.userid = u.id
        GROUP BY u.id
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(v.id) AS votes_received_count,
            SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvotes_received,
            SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvotes_received
        FROM posts p
        JOIN votes v ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            u.id AS user_id,
            COUNT(b.id) AS badge_count
        FROM users u
        JOIN badges b ON b.userid = u.id
        GROUP BY u.id
    ),
    user_postedits AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(ph.id) AS edit_count
        FROM posts p
        JOIN posthistory ph ON ph.posthistorytypeid = p.id
        GROUP BY p.owneruserid
    ),
    user_tags AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(DISTINCT t.id) AS distinct_tag_count
        FROM posts p
        JOIN tags t ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_score_avg, 0) AS post_score_avg,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(vc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vc.upvotes_cast, 0) AS upvotes_cast,
    COALESCE(vc.downvotes_cast, 0) AS downvotes_cast,
    COALESCE(vr.votes_received_count, 0) AS votes_received_count,
    COALESCE(vr.upvotes_received, 0) AS upvotes_received,
    COALESCE(vr.downvotes_received, 0) AS downvotes_received,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(t.distinct_tag_count, 0) AS distinct_tag_count
FROM users u
LEFT JOIN user_posts up          ON up.user_id = u.id
LEFT JOIN user_comments uc       ON uc.user_id = u.id
LEFT JOIN user_votes_cast vc     ON vc.user_id = u.id
LEFT JOIN user_votes_received vr ON vr.user_id = u.id
LEFT JOIN user_badges b          ON b.user_id = u.id
LEFT JOIN user_postedits e       ON e.user_id = u.id
LEFT JOIN user_tags t            ON t.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
