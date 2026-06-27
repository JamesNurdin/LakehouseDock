-- Analytical query: user activity and content metrics
WITH
    user_posts AS (
        SELECT
            owneruserid,
            COUNT(*) AS post_count,
            SUM(score) AS total_score,
            SUM(viewcount) AS total_views,
            SUM(answercount) AS total_answers,
            SUM(commentcount) AS total_comments,
            SUM(favoritecount) AS total_favorites
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments_authored AS (
        SELECT
            userid,
            COUNT(*) AS comment_authored_count,
            SUM(score) AS comment_authored_score_sum
        FROM comments
        GROUP BY userid
    ),
    user_comments_on_own_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS comment_on_own_posts,
            SUM(c.score) AS comment_on_own_score
        FROM comments c
        JOIN posts p ON c.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_votes_cast AS (
        SELECT
            userid,
            COUNT(*) AS vote_cast_count
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS vote_received_count
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
    user_postlinks AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0)                AS post_count,
    COALESCE(up.total_score, 0)               AS total_post_score,
    COALESCE(up.total_views, 0)               AS total_viewcount,
    COALESCE(up.total_answers, 0)             AS total_answercount,
    COALESCE(up.total_comments, 0)            AS total_commentcount,
    COALESCE(up.total_favorites, 0)           AS total_favoritecount,
    COALESCE(uca.comment_authored_count, 0)   AS comment_authored_count,
    COALESCE(uca.comment_authored_score_sum, 0) AS comment_authored_score_sum,
    COALESCE(uco.comment_on_own_posts, 0)     AS comment_on_own_posts,
    COALESCE(uco.comment_on_own_score, 0)     AS comment_on_own_score,
    COALESCE(vc.vote_cast_count, 0)           AS vote_cast_count,
    COALESCE(vr.vote_received_count, 0)       AS vote_received_count,
    COALESCE(b.badge_count, 0)                AS badge_count,
    COALESCE(ph.posthistory_count, 0)         AS posthistory_count,
    COALESCE(pl.postlink_count, 0)            AS postlink_count
FROM users u
LEFT JOIN user_posts up               ON up.owneruserid = u.id
LEFT JOIN user_comments_authored uca   ON uca.userid = u.id
LEFT JOIN user_comments_on_own_posts uco ON uco.user_id = u.id
LEFT JOIN user_votes_cast vc          ON vc.userid = u.id
LEFT JOIN user_votes_received vr      ON vr.user_id = u.id
LEFT JOIN user_badges b               ON b.userid = u.id
LEFT JOIN user_posthistory ph          ON ph.userid = u.id
LEFT JOIN user_postlinks pl            ON pl.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 100
