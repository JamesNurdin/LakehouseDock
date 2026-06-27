WITH user_posts AS (
    SELECT
        owneruserid,
        COUNT(*) AS post_count,
        COALESCE(SUM(score), 0) AS total_post_score,
        COALESCE(SUM(viewcount), 0) AS total_views,
        COALESCE(SUM(answercount), 0) AS total_answers,
        COALESCE(SUM(commentcount), 0) AS total_comments,
        COALESCE(SUM(favoritecount), 0) AS total_favorites
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        COALESCE(SUM(score), 0) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid,
        COUNT(*) AS vote_count,
        COALESCE(SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END), 0) AS upvote_cast,
        COALESCE(SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END), 0) AS downvote_cast,
        COALESCE(SUM(bountyamount), 0) AS total_bounty_given
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_views, 0) AS total_views,
    COALESCE(up.total_answers, 0) AS total_answers,
    COALESCE(up.total_comments, 0) AS total_comments,
    COALESCE(up.total_favorites, 0) AS total_favorites,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uc.total_comment_score, 0) AS total_comment_score,
    COALESCE(uv.vote_count, 0) AS vote_count,
    COALESCE(uv.upvote_cast, 0) AS upvote_cast,
    COALESCE(uv.downvote_cast, 0) AS downvote_cast,
    COALESCE(uv.total_bounty_given, 0) AS total_bounty_given,
    COALESCE(ub.badge_count, 0) AS badge_count
FROM users u
LEFT JOIN user_posts up ON up.owneruserid = u.id
LEFT JOIN user_comments uc ON uc.userid = u.id
LEFT JOIN user_votes uv ON uv.userid = u.id
LEFT JOIN user_badges ub ON ub.userid = u.id
ORDER BY u.reputation DESC
LIMIT 20
