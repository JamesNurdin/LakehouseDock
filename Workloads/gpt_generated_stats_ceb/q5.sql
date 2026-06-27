WITH owner_stats AS (
    SELECT
        u.id AS user_id,
        u.reputation,
        COUNT(p.id) AS owned_post_count,
        SUM(p.score) AS owned_total_score,
        AVG(p.score) AS owned_avg_score,
        SUM(p.viewcount) AS owned_total_views,
        SUM(p.favoritecount) AS owned_total_favorites,
        SUM(p.commentcount) AS owned_total_comments,
        SUM(p.answercount) AS owned_total_answers
    FROM posts p
    JOIN users u
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
editor_stats AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS edited_post_count,
        SUM(p.score) AS edited_total_score,
        AVG(p.score) AS edited_avg_score,
        SUM(p.viewcount) AS edited_total_views,
        SUM(p.favoritecount) AS edited_total_favorites,
        SUM(p.commentcount) AS edited_total_comments,
        SUM(p.answercount) AS edited_total_answers
    FROM posts p
    JOIN users u
        ON p.lasteditoruserid = u.id
    GROUP BY u.id
)
SELECT
    COALESCE(o.user_id, e.user_id) AS user_id,
    o.reputation,
    o.owned_post_count,
    o.owned_total_score,
    o.owned_avg_score,
    o.owned_total_views,
    o.owned_total_favorites,
    o.owned_total_comments,
    o.owned_total_answers,
    e.edited_post_count,
    e.edited_total_score,
    e.edited_avg_score,
    e.edited_total_views,
    e.edited_total_favorites,
    e.edited_total_comments,
    e.edited_total_answers
FROM owner_stats o
FULL OUTER JOIN editor_stats e
    ON o.user_id = e.user_id
ORDER BY o.reputation DESC NULLS LAST
LIMIT 100
