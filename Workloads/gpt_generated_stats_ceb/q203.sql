WITH authored_posts AS (
    SELECT
        p.owneruserid,
        COUNT(*) AS authored_post_count,
        SUM(p.score) AS authored_total_score,
        AVG(p.viewcount) AS authored_avg_viewcount,
        SUM(p.answercount) AS authored_total_answers,
        SUM(p.commentcount) AS authored_total_comments,
        SUM(p.favoritecount) AS authored_total_favorites
    FROM posts p
    GROUP BY p.owneruserid
),
edited_posts AS (
    SELECT
        p.lasteditoruserid,
        COUNT(*) AS edited_post_count,
        SUM(p.score) AS edited_total_score,
        AVG(p.viewcount) AS edited_avg_viewcount
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
)
SELECT
    u.id,
    u.reputation,
    COALESCE(a.authored_post_count, 0) AS authored_post_count,
    COALESCE(a.authored_total_score, 0) AS authored_total_score,
    COALESCE(a.authored_avg_viewcount, 0) AS authored_avg_viewcount,
    COALESCE(a.authored_total_answers, 0) AS authored_total_answers,
    COALESCE(a.authored_total_comments, 0) AS authored_total_comments,
    COALESCE(a.authored_total_favorites, 0) AS authored_total_favorites,
    COALESCE(e.edited_post_count, 0) AS edited_post_count,
    COALESCE(e.edited_total_score, 0) AS edited_total_score,
    COALESCE(e.edited_avg_viewcount, 0) AS edited_avg_viewcount,
    (COALESCE(a.authored_total_score, 0) + 0.5 * COALESCE(e.edited_total_score, 0)) AS total_contribution_score
FROM users u
LEFT JOIN authored_posts a ON u.id = a.owneruserid
LEFT JOIN edited_posts e ON u.id = e.lasteditoruserid
ORDER BY total_contribution_score DESC
LIMIT 10
