WITH comment_stats AS (
    SELECT
        postid,
        COUNT(*) AS comment_cnt,
        SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY postid
),
vote_stats AS (
    SELECT
        postid,
        COUNT(*) AS vote_cnt,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cnt,
        SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cnt
    FROM votes
    GROUP BY postid
),
post_user_stats AS (
    SELECT
        users.id AS user_id,
        users.reputation,
        COUNT(posts.id) AS post_cnt,
        SUM(posts.score) AS total_post_score,
        AVG(posts.score) AS avg_post_score,
        COALESCE(SUM(comment_stats.comment_cnt), 0) AS total_comment_cnt,
        COALESCE(SUM(comment_stats.comment_score_sum), 0) AS total_comment_score_sum,
        COALESCE(SUM(vote_stats.vote_cnt), 0) AS total_vote_cnt,
        COALESCE(SUM(vote_stats.upvote_cnt), 0) AS total_upvote_cnt,
        COALESCE(SUM(vote_stats.downvote_cnt), 0) AS total_downvote_cnt
    FROM posts
    LEFT JOIN comment_stats
        ON comment_stats.postid = posts.id
    LEFT JOIN vote_stats
        ON vote_stats.postid = posts.id
    JOIN users
        ON users.id = posts.owneruserid
    GROUP BY users.id, users.reputation
)
SELECT
    user_id,
    reputation,
    post_cnt,
    total_post_score,
    avg_post_score,
    total_comment_cnt,
    CASE
        WHEN total_comment_cnt > 0 THEN total_comment_score_sum / total_comment_cnt
        ELSE NULL
    END AS avg_comment_score,
    total_vote_cnt,
    total_upvote_cnt,
    total_downvote_cnt
FROM post_user_stats
ORDER BY post_cnt DESC
LIMIT 100
