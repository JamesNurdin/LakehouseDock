WITH
    user_posts AS (
        SELECT
            owneruserid,
            COUNT(*) AS post_count,
            COALESCE(SUM(score), 0) AS total_post_score,
            COALESCE(SUM(answercount), 0) AS total_answer_count,
            COALESCE(SUM(commentcount), 0) AS total_comment_on_posts,
            COALESCE(SUM(viewcount), 0) AS total_views
        FROM posts
        GROUP BY owneruserid
    ),
    user_comments AS (
        SELECT
            userid,
            COUNT(*) AS comment_count
        FROM comments
        GROUP BY userid
    ),
    user_votes AS (
        SELECT
            userid,
            COUNT(*) AS vote_count
        FROM votes
        GROUP BY userid
    ),
    user_badges AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_edits AS (
        SELECT
            userid,
            COUNT(*) AS edit_count
        FROM posthistory
        GROUP BY userid
    ),
    user_postlinks_raw AS (
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS link_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
        UNION ALL
        SELECT
            p.owneruserid AS userid,
            COUNT(*) AS link_count
        FROM postlinks pl
        JOIN posts p ON pl.relatedpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks_agg AS (
        SELECT
            userid,
            SUM(link_count) AS postlink_count
        FROM user_postlinks_raw
        GROUP BY userid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_on_posts, 0) AS total_comment_on_posts,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ue.edit_count, 0) AS edit_count,
    COALESCE(upl.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes uv ON uv.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_edits ue ON ue.userid = u.id
LEFT JOIN user_postlinks_agg upl ON upl.userid = u.id
ORDER BY total_post_score DESC
LIMIT 100
