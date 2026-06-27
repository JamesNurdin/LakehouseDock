-- User activity summary across posts, comments, votes, badges, and post history
WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(score) AS total_post_score,
        AVG(score) AS avg_post_score,
        SUM(viewcount) AS total_viewcount,
        SUM(answercount) AS total_answer_count,
        SUM(commentcount) AS total_comment_count,
        SUM(favoritecount) AS total_favorite_count
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count,
        SUM(score) AS total_comment_score,
        AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS vote_count,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_count,
        SUM(CASE WHEN votetypeid = 3 THEN bountyamount ELSE 0 END) AS total_bounty_given
    FROM votes
    GROUP BY userid
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
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0)               AS post_count,
    COALESCE(up.total_post_score, 0)         AS total_post_score,
    COALESCE(up.avg_post_score, 0)           AS avg_post_score,
    COALESCE(up.total_viewcount, 0)          AS total_viewcount,
    COALESCE(up.total_answer_count, 0)      AS total_answer_count,
    COALESCE(up.total_comment_count, 0)      AS total_comment_count,
    COALESCE(up.total_favorite_count, 0)    AS total_favorite_count,
    COALESCE(uc.comment_count, 0)            AS comment_count,
    COALESCE(uc.total_comment_score, 0)      AS total_comment_score,
    COALESCE(uc.avg_comment_score, 0)        AS avg_comment_score,
    COALESCE(uv.vote_count, 0)               AS vote_count,
    COALESCE(uv.upvote_count, 0)             AS upvote_count,
    COALESCE(uv.downvote_count, 0)           AS downvote_count,
    COALESCE(uv.total_bounty_given, 0)       AS total_bounty_given,
    COALESCE(ub.badge_count, 0)              AS badge_count,
    COALESCE(uph.posthistory_count, 0)       AS posthistory_count
FROM users u
LEFT JOIN user_posts up          ON up.user_id = u.id
LEFT JOIN user_comments uc      ON uc.user_id = u.id
LEFT JOIN user_votes uv         ON uv.user_id = u.id
LEFT JOIN user_badges ub        ON ub.user_id = u.id
LEFT JOIN user_posthistory uph  ON uph.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
