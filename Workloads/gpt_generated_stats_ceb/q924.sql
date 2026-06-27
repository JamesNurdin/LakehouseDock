WITH user_posts AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(score) AS total_post_score,
        AVG(score) AS avg_post_score,
        SUM(answercount) AS total_answer_count,
        SUM(commentcount) AS total_comment_on_posts,
        SUM(favoritecount) AS total_favorite_count
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
        COUNT(*) AS votes_cast,
        SUM(CASE WHEN votetypeid = 1 THEN 1 ELSE 0 END) AS upvote_cast,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS downvote_cast
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
user_tags AS (
    SELECT
        p.owneruserid AS userid,
        COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM posts p
    JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.avg_post_score, 0) AS avg_post_score,
    COALESCE(up.total_answer_count, 0) AS total_answer_count,
    COALESCE(up.total_comment_on_posts, 0) AS total_comment_on_posts,
    COALESCE(up.total_favorite_count, 0) AS total_favorite_count,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uv.votes_cast, 0) AS votes_cast,
    COALESCE(uv.upvote_cast, 0) AS upvote_cast,
    COALESCE(uv.downvote_cast, 0) AS downvote_cast,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(ut.distinct_tag_count, 0) AS distinct_tag_count
FROM users u
LEFT JOIN user_posts up
    ON up.userid = u.id
LEFT JOIN user_comments uc
    ON uc.userid = u.id
LEFT JOIN user_votes uv
    ON uv.userid = u.id
LEFT JOIN user_badges ub
    ON ub.userid = u.id
LEFT JOIN user_tags ut
    ON ut.userid = u.id
ORDER BY total_post_score DESC
LIMIT 100
