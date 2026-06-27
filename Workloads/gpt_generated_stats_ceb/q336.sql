WITH user_posts AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(score) AS total_post_score,
        AVG(score) AS avg_post_score,
        SUM(viewcount) AS total_viewcount,
        SUM(favoritecount) AS total_favoritecount,
        SUM(commentcount) AS total_commentcount,
        SUM(answercount) AS total_answercount,
        SUM(CASE WHEN posttypeid = 1 THEN 1 ELSE 0 END) AS question_count,
        SUM(CASE WHEN posttypeid = 2 THEN 1 ELSE 0 END) AS answer_count
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count,
        SUM(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS vote_count,
        SUM(votetypeid) AS sum_votetypeid
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
        COUNT(*) AS history_count
    FROM posthistory
    GROUP BY userid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.question_count, 0) AS question_count,
    COALESCE(p.answer_count, 0) AS answer_count,
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    COALESCE(p.total_favoritecount, 0) AS total_favoritecount,
    COALESCE(p.total_commentcount, 0) AS total_commentcount,
    COALESCE(p.total_answercount, 0) AS total_answercount,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.sum_votetypeid, 0) AS sum_votetypeid,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(h.history_count, 0) AS posthistory_count,
    COALESCE(t.tag_count, 0) AS tag_count
FROM users u
LEFT JOIN user_posts p ON p.user_id = u.id
LEFT JOIN user_comments c ON c.user_id = u.id
LEFT JOIN user_votes v ON v.user_id = u.id
LEFT JOIN user_badges b ON b.user_id = u.id
LEFT JOIN user_posthistory h ON h.user_id = u.id
LEFT JOIN user_tags t ON t.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 10
