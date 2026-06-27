WITH user_posts AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        p.id AS post_id,
        p.score,
        p.viewcount,
        p.answercount
    FROM posts p
    JOIN users u ON p.owneruserid = u.id
),
post_tags AS (
    SELECT
        p.id AS post_id,
        COUNT(t.id) AS tag_count
    FROM posts p
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.id
),
user_aggregates AS (
    SELECT
        up.user_id,
        up.reputation,
        COUNT(up.post_id) AS total_posts,
        SUM(up.score) AS total_score,
        AVG(up.score) AS avg_score,
        SUM(up.viewcount) AS total_views,
        AVG(up.viewcount) AS avg_views,
        SUM(up.answercount) AS total_answers,
        AVG(up.answercount) AS avg_answers,
        COALESCE(SUM(pt.tag_count), 0) AS total_tags
    FROM user_posts up
    LEFT JOIN post_tags pt ON up.post_id = pt.post_id
    GROUP BY up.user_id, up.reputation
)
SELECT
    ua.user_id,
    ua.reputation,
    ua.total_posts,
    ua.total_score,
    ua.avg_score,
    ua.total_views,
    ua.avg_views,
    ua.total_answers,
    ua.avg_answers,
    ua.total_tags,
    ROW_NUMBER() OVER (ORDER BY ua.total_score DESC) AS rank_by_score
FROM user_aggregates ua
ORDER BY ua.total_score DESC
LIMIT 10
