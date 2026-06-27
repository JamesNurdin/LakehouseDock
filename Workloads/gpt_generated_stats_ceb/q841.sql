WITH user_base AS (
    SELECT
        id AS user_id,
        reputation,
        creationdate AS user_creationdate,
        views,
        upvotes,
        downvotes
    FROM users
),
post_stats AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        COUNT(*) FILTER (WHERE posttypeid = 1) AS question_count,
        COUNT(*) FILTER (WHERE posttypeid = 2) AS answer_count,
        SUM(score) AS total_post_score,
        AVG(score) AS avg_post_score,
        SUM(answercount) AS total_answer_count,
        SUM(commentcount) AS total_comment_count,
        SUM(favoritecount) AS total_favorite_count
    FROM posts
    GROUP BY owneruserid
),
comment_stats AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
badge_stats AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
vote_cast_stats AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS vote_cast_count
    FROM votes
    GROUP BY userid
),
vote_received_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS vote_received_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
edit_stats AS (
    SELECT
        lasteditoruserid AS user_id,
        COUNT(*) AS edit_count
    FROM posts
    GROUP BY lasteditoruserid
)
SELECT
    ub.user_id,
    ub.reputation,
    ub.user_creationdate,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.question_count, 0) AS question_count,
    COALESCE(ps.answer_count, 0) AS answer_count,
    COALESCE(ps.total_post_score, 0) AS total_post_score,
    COALESCE(ps.avg_post_score, 0) AS avg_post_score,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(vcs.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(vrs.vote_received_count, 0) AS vote_received_count,
    COALESCE(bs.badge_count, 0) AS badge_count,
    COALESCE(es.edit_count, 0) AS edit_count
FROM user_base ub
LEFT JOIN post_stats ps ON ps.user_id = ub.user_id
LEFT JOIN comment_stats cs ON cs.user_id = ub.user_id
LEFT JOIN badge_stats bs ON bs.user_id = ub.user_id
LEFT JOIN vote_cast_stats vcs ON vcs.user_id = ub.user_id
LEFT JOIN vote_received_stats vrs ON vrs.user_id = ub.user_id
LEFT JOIN edit_stats es ON es.user_id = ub.user_id
WHERE ub.reputation >= 1000
ORDER BY post_count DESC
LIMIT 100
