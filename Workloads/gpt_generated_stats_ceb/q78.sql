WITH user_metrics AS (
    SELECT
        id,
        reputation,
        creationdate,
        views,
        upvotes,
        downvotes
    FROM users
),
badge_counts AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
post_counts AS (
    SELECT
        owneruserid,
        COUNT(*) AS post_count,
        SUM(CASE WHEN posttypeid = 1 THEN 1 ELSE 0 END) AS question_count,
        SUM(CASE WHEN posttypeid = 2 THEN 1 ELSE 0 END) AS answer_count,
        AVG(score) AS avg_post_score,
        SUM(viewcount) AS total_views,
        SUM(answercount) AS total_answers_to_questions
    FROM posts
    GROUP BY owneruserid
),
comment_counts AS (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY userid
),
comment_received AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(*) AS comment_received_count,
        AVG(c.score) AS avg_received_comment_score
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
),
vote_cast_counts AS (
    SELECT
        userid,
        COUNT(*) AS vote_cast_count
    FROM votes
    GROUP BY userid
),
vote_received_counts AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(*) AS vote_received_count
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY p.owneruserid
),
tag_counts AS (
    SELECT
        p.owneruserid AS owneruserid,
        COUNT(DISTINCT t.id) AS distinct_tag_count,
        SUM(t.count) AS tag_usage_sum
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.question_count, 0) AS question_count,
    COALESCE(p.answer_count, 0) AS answer_count,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_views, 0) AS total_views,
    COALESCE(p.total_answers_to_questions, 0) AS total_answers_to_questions,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(cr.comment_received_count, 0) AS comment_received_count,
    COALESCE(cr.avg_received_comment_score, 0) AS avg_received_comment_score,
    COALESCE(vc.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(vr.vote_received_count, 0) AS vote_received_count,
    COALESCE(t.distinct_tag_count, 0) AS distinct_tag_count,
    COALESCE(t.tag_usage_sum, 0) AS tag_usage_sum
FROM user_metrics u
LEFT JOIN badge_counts b ON b.userid = u.id
LEFT JOIN post_counts p ON p.owneruserid = u.id
LEFT JOIN comment_counts c ON c.userid = u.id
LEFT JOIN comment_received cr ON cr.owneruserid = u.id
LEFT JOIN vote_cast_counts vc ON vc.userid = u.id
LEFT JOIN vote_received_counts vr ON vr.owneruserid = u.id
LEFT JOIN tag_counts t ON t.owneruserid = u.id
ORDER BY u.reputation DESC
LIMIT 100
