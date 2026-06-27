WITH posts_monthly AS (
    SELECT
        date_trunc('month', creationdate) AS month,
        COUNT(*) AS total_posts,
        SUM(answercount) AS total_answers,
        SUM(viewcount) AS total_views,
        AVG(score) AS avg_score,
        SUM(commentcount) AS total_comments,
        COUNT(DISTINCT owneruserid) AS distinct_users
    FROM posts
    GROUP BY date_trunc('month', creationdate)
),
votes_monthly AS (
    SELECT
        date_trunc('month', p.creationdate) AS month,
        COUNT(v.id) AS total_votes
    FROM votes v
    JOIN posts p ON v.postid = p.id
    GROUP BY date_trunc('month', p.creationdate)
),
tags_monthly AS (
    SELECT
        date_trunc('month', p.creationdate) AS month,
        COUNT(DISTINCT t.id) AS distinct_tags
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY date_trunc('month', p.creationdate)
),
badges_monthly AS (
    SELECT
        date_trunc('month', date) AS month,
        COUNT(DISTINCT id) AS distinct_badges
    FROM badges
    GROUP BY date_trunc('month', date)
)
SELECT
    p.month,
    p.total_posts,
    p.total_answers,
    p.total_views,
    p.avg_score,
    p.total_comments,
    p.distinct_users,
    COALESCE(v.total_votes, 0) AS total_votes,
    COALESCE(t.distinct_tags, 0) AS distinct_tags,
    COALESCE(b.distinct_badges, 0) AS distinct_badges
FROM posts_monthly p
LEFT JOIN votes_monthly v ON p.month = v.month
LEFT JOIN tags_monthly t ON p.month = t.month
LEFT JOIN badges_monthly b ON p.month = b.month
ORDER BY p.month DESC
