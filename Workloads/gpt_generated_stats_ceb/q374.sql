/*
  User activity summary – combines badge totals, post statistics (questions vs. answers, scores, views),
  comment scores, and voting activity for each user, ordered by reputation.
*/
WITH badge_counts AS (
    SELECT
        userid,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
post_metrics AS (
    SELECT
        owneruserid AS userid,
        COUNT(*) AS post_count,
        SUM(CASE WHEN posttypeid = 1 THEN 1 ELSE 0 END) AS question_count,
        SUM(CASE WHEN posttypeid = 2 THEN 1 ELSE 0 END) AS answer_count,
        SUM(score) AS total_post_score,
        AVG(score) AS avg_post_score,
        SUM(viewcount) AS total_viewcount,
        AVG(viewcount) AS avg_viewcount
    FROM posts
    GROUP BY owneruserid
),
comment_metrics AS (
    SELECT
        userid,
        COUNT(*) AS comment_count,
        SUM(score) AS total_comment_score,
        AVG(score) AS avg_comment_score
    FROM comments
    GROUP BY userid
),
vote_metrics AS (
    SELECT
        userid,
        COUNT(*) AS vote_cast_count,
        SUM(CASE WHEN votetypeid = 2 THEN 1 ELSE 0 END) AS upvote_cast,
        SUM(CASE WHEN votetypeid = 3 THEN 1 ELSE 0 END) AS downvote_cast
    FROM votes
    GROUP BY userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.question_count, 0) AS question_count,
    COALESCE(pm.answer_count, 0) AS answer_count,
    COALESCE(pm.total_post_score, 0) AS total_post_score,
    COALESCE(pm.avg_post_score, 0) AS avg_post_score,
    COALESCE(pm.total_viewcount, 0) AS total_viewcount,
    COALESCE(pm.avg_viewcount, 0) AS avg_viewcount,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(cm.total_comment_score, 0) AS total_comment_score,
    COALESCE(cm.avg_comment_score, 0) AS avg_comment_score,
    COALESCE(vm.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(vm.upvote_cast, 0) AS upvote_cast,
    COALESCE(vm.downvote_cast, 0) AS downvote_cast
FROM users u
LEFT JOIN badge_counts bc ON bc.userid = u.id
LEFT JOIN post_metrics pm ON pm.userid = u.id
LEFT JOIN comment_metrics cm ON cm.userid = u.id
LEFT JOIN vote_metrics vm ON vm.userid = u.id
ORDER BY u.reputation DESC
LIMIT 100
