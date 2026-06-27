WITH owner_stats AS (
    SELECT
        u.id AS owner_id,
        u.reputation AS owner_reputation,
        COUNT(p.id) AS post_count,
        SUM(p.score) AS total_score,
        AVG(p.viewcount) AS avg_viewcount,
        SUM(p.answercount) AS total_answers,
        SUM(p.commentcount) AS total_comments,
        SUM(p.favoritecount) AS total_favorites
    FROM posts p
    JOIN users u ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
editor_stats AS (
    SELECT
        u.id AS editor_id,
        COUNT(p.id) AS edit_count,
        SUM(p.score) AS edit_total_score
    FROM posts p
    JOIN users u ON p.lasteditoruserid = u.id
    GROUP BY u.id
)
SELECT
    o.owner_id,
    o.owner_reputation,
    o.post_count,
    o.total_score,
    o.avg_viewcount,
    o.total_answers,
    o.total_comments,
    o.total_favorites,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(e.edit_total_score, 0) AS edit_total_score,
    (o.total_score * 1.0) / NULLIF(o.post_count, 0) AS avg_score_per_post,
    ROW_NUMBER() OVER (ORDER BY o.total_score DESC) AS owner_score_rank
FROM owner_stats o
LEFT JOIN editor_stats e ON o.owner_id = e.editor_id
ORDER BY o.total_score DESC
LIMIT 100
