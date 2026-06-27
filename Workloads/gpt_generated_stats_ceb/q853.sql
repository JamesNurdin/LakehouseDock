WITH
    user_posts AS (
        SELECT
            owneruserid,
            COUNT(*) AS post_count,
            SUM(score) AS post_score_sum,
            SUM(viewcount) AS post_viewcount_sum
        FROM posts
        GROUP BY owneruserid
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
            COUNT(*) AS votes_cast_count
        FROM votes
        GROUP BY userid
    ),
    user_votes_received AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS votes_received_count
        FROM votes v
        JOIN posts p
            ON v.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_badges AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    user_postlinks AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p
            ON pl.postid = p.id
        GROUP BY p.owneruserid
    ),
    user_tags AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS tag_count
        FROM tags t
        JOIN posts p
            ON t.excerptpostid = p.id
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
    COALESCE(up.post_score_sum, 0) AS post_score_sum,
    COALESCE(up.post_viewcount_sum, 0) AS post_viewcount_sum,
    CASE
        WHEN COALESCE(up.post_count, 0) > 0 THEN up.post_score_sum / up.post_count
        ELSE NULL
    END AS avg_post_score,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.comment_score_sum, 0) AS comment_score_sum,
    CASE
        WHEN COALESCE(uc.comment_count, 0) > 0 THEN uc.comment_score_sum / uc.comment_count
        ELSE NULL
    END AS avg_comment_score,
    COALESCE(uvc.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(uvrc.votes_received_count, 0) AS votes_received_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(upk.postlink_count, 0) AS postlink_count,
    COALESCE(ut.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes_cast uvc ON uvc.userid = u.id
LEFT JOIN user_votes_received uvrc ON uvrc.owneruserid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
LEFT JOIN user_postlinks upk ON upk.owneruserid = u.id
LEFT JOIN user_tags ut ON ut.owneruserid = u.id
ORDER BY post_score_sum DESC
LIMIT 10
