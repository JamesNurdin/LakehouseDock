WITH owner_stats AS (
    SELECT
        u.id,
        u.reputation,
        COUNT(p.id) AS owned_posts,
        SUM(p.score) AS total_score_owned,
        AVG(p.score) AS avg_score_owned,
        SUM(p.viewcount) AS total_views_owned,
        MAX(p.answercount) AS max_answers_owned,
        SUM(p.favoritecount) AS total_favorites_owned
    FROM posts p
    JOIN users u
        ON p.owneruserid = u.id
    GROUP BY u.id, u.reputation
),
editor_stats AS (
    SELECT
        u.id,
        u.reputation,
        COUNT(p.id) AS edited_posts,
        SUM(p.score) AS total_score_edited,
        AVG(p.score) AS avg_score_edited,
        SUM(p.viewcount) AS total_views_edited,
        MAX(p.answercount) AS max_answers_edited,
        SUM(p.favoritecount) AS total_favorites_edited
    FROM posts p
    JOIN users u
        ON p.lasteditoruserid = u.id
    GROUP BY u.id, u.reputation
)
SELECT
    COALESCE(os.id, es.id) AS user_id,
    COALESCE(os.reputation, es.reputation) AS reputation,
    COALESCE(os.owned_posts, 0) AS owned_posts,
    COALESCE(es.edited_posts, 0) AS edited_posts,
    COALESCE(os.total_score_owned, 0) AS total_score_owned,
    COALESCE(es.total_score_edited, 0) AS total_score_edited,
    COALESCE(os.avg_score_owned, 0) AS avg_score_owned,
    COALESCE(es.avg_score_edited, 0) AS avg_score_edited,
    COALESCE(os.total_views_owned, 0) AS total_views_owned,
    COALESCE(es.total_views_edited, 0) AS total_views_edited,
    COALESCE(os.max_answers_owned, 0) AS max_answers_owned,
    COALESCE(es.max_answers_edited, 0) AS max_answers_edited,
    COALESCE(os.total_favorites_owned, 0) AS total_favorites_owned,
    COALESCE(es.total_favorites_edited, 0) AS total_favorites_edited,
    CASE WHEN COALESCE(es.edited_posts, 0) > 0
         THEN COALESCE(os.owned_posts, 0) / COALESCE(es.edited_posts, 1)
         ELSE NULL
    END AS owned_to_edited_ratio
FROM owner_stats os
FULL OUTER JOIN editor_stats es
    ON os.id = es.id
ORDER BY reputation DESC
LIMIT 100
