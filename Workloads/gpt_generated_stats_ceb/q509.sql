WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(score) AS post_score_sum,
        SUM(viewcount) AS post_viewcount_sum,
        SUM(answercount) AS post_answer_count_sum,
        SUM(commentcount) AS post_comment_count_sum,
        SUM(favoritecount) AS post_favorite_count_sum
    FROM posts
    GROUP BY owneruserid
),
user_posts_edited AS (
    SELECT
        lasteditoruserid AS user_id,
        COUNT(*) AS edited_post_count
    FROM posts
    GROUP BY lasteditoruserid
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
user_votes_cast AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS votes_cast_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cast_count,
        SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cast_count
    FROM votes
    GROUP BY userid
),
user_votes_received AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received_count,
        SUM(CASE WHEN v.votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_received_count,
        SUM(CASE WHEN v.votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_received_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
user_badges AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_posthistory AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory
    GROUP BY userid
)
SELECT
    u.id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0)                     AS post_count,
    COALESCE(up.post_score_sum, 0)                AS post_score_sum,
    COALESCE(upc.edited_post_count, 0)            AS edited_post_count,
    COALESCE(uc.comment_count, 0)                 AS comment_count,
    COALESCE(uc.comment_score_sum, 0)             AS comment_score_sum,
    COALESCE(uvc.votes_cast_count, 0)             AS votes_cast_count,
    COALESCE(uvc.upvote_cast_count, 0)            AS upvote_cast_count,
    COALESCE(uvc.downvote_cast_count, 0)          AS downvote_cast_count,
    COALESCE(uvr.votes_received_count, 0)         AS votes_received_count,
    COALESCE(uvr.upvote_received_count, 0)        AS upvote_received_count,
    COALESCE(uvr.downvote_received_count, 0)      AS downvote_received_count,
    COALESCE(ub.badge_count, 0)                   AS badge_count,
    COALESCE(uph.posthistory_count, 0)            AS posthistory_count
FROM users u
LEFT JOIN user_posts up               ON up.user_id = u.id
LEFT JOIN user_posts_edited upc        ON upc.user_id = u.id
LEFT JOIN user_comments uc            ON uc.user_id = u.id
LEFT JOIN user_votes_cast uvc         ON uvc.user_id = u.id
LEFT JOIN user_votes_received uvr     ON uvr.user_id = u.id
LEFT JOIN user_badges ub              ON ub.user_id = u.id
LEFT JOIN user_posthistory uph        ON uph.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
