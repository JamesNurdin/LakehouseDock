WITH tag_post_stats AS (
    SELECT
        t.id AS tag_id,
        p.id AS post_id,
        p.score,
        p.viewcount,
        p.answercount,
        p.commentcount,
        p.favoritecount,
        t.count AS tag_usage_count
    FROM tags t
    JOIN posts p
        ON t.excerptpostid = p.id
)
SELECT
    tag_id,
    COUNT(*) AS excerpt_post_count,
    SUM(score) AS total_score,
    AVG(viewcount) AS avg_viewcount,
    SUM(answercount) AS total_answers,
    SUM(commentcount) AS total_comments,
    SUM(favoritecount) AS total_favorites,
    SUM(tag_usage_count) AS total_tag_usage,
    (SUM(score) * 1.0) / NULLIF(SUM(tag_usage_count), 0) AS score_per_tag_usage,
    (SUM(score) * 1.0) / NULLIF(COUNT(*), 0) AS avg_score_per_excerpt
FROM tag_post_stats
GROUP BY tag_id
HAVING SUM(tag_usage_count) > 10
ORDER BY total_score DESC
LIMIT 10
