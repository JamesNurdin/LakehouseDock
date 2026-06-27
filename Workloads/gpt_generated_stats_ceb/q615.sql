WITH post_engagement AS (
    SELECT
        id AS post_id,
        score,
        viewcount,
        answercount,
        favoritecount,
        commentcount,
        (viewcount + favoritecount * 10 + answercount * 5 + commentcount * 2) AS total_engagement
    FROM posts
    WHERE posttypeid = 1
)
SELECT
    t.id AS tag_id,
    t.count AS tag_post_count,
    COUNT(*) AS excerpt_post_count,
    SUM(pe.score) AS total_score,
    AVG(pe.score) AS avg_score,
    SUM(pe.viewcount) AS total_views,
    AVG(pe.viewcount) AS avg_views,
    SUM(pe.total_engagement) AS total_engagement,
    AVG(pe.total_engagement) AS avg_engagement,
    SUM(CASE WHEN pe.favoritecount > 0 THEN 1 ELSE 0 END) AS posts_with_favorites
FROM tags t
JOIN post_engagement pe
    ON t.excerptpostid = pe.post_id
GROUP BY t.id, t.count
ORDER BY total_score DESC
LIMIT 10
