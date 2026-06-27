WITH post_tag_stats AS (
    SELECT
        p.posttypeid,
        t.id AS tag_id,
        COUNT(*) AS post_count,
        SUM(p.score) AS total_score,
        AVG(p.score) AS avg_score,
        SUM(p.viewcount) AS total_views,
        SUM(p.answercount) AS total_answers,
        SUM(p.commentcount) AS total_comments,
        SUM(p.favoritecount) AS total_favorites,
        SUM(t.count) AS total_tag_count
    FROM posts p
    JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY p.posttypeid, t.id
    HAVING COUNT(*) >= 5
)
SELECT
    posttypeid,
    tag_id,
    post_count,
    total_score,
    avg_score,
    total_views,
    total_answers,
    total_comments,
    total_favorites,
    total_tag_count
FROM post_tag_stats
ORDER BY total_tag_count DESC
LIMIT 20
