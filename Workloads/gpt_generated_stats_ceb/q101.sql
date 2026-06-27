WITH tag_post_stats AS (
    SELECT
        t.id AS tag_id,
        t.count AS tag_usage_count,
        COUNT(p.id) AS excerpt_post_count,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_viewcount,
        SUM(p.favoritecount) AS total_favoritecount,
        SUM(p.answercount) AS total_answercount,
        SUM(p.commentcount) AS total_commentcount,
        MAX(p.creationdate) AS latest_excerpt_post_date
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
    GROUP BY t.id, t.count
)
SELECT
    tag_id,
    tag_usage_count,
    excerpt_post_count,
    avg_post_score,
    total_viewcount,
    total_favoritecount,
    total_answercount,
    total_commentcount,
    latest_excerpt_post_date,
    ROW_NUMBER() OVER (ORDER BY avg_post_score DESC) AS rank_by_avg_score
FROM tag_post_stats
ORDER BY rank_by_avg_score
LIMIT 20
