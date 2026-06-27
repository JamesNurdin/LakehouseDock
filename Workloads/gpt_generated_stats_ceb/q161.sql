WITH owner_stats AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS owned_post_count,
        SUM(p.score) AS owned_total_score,
        AVG(p.score) AS owned_avg_score,
        SUM(p.viewcount) AS owned_total_views,
        SUM(p.answercount) AS owned_total_answers,
        SUM(p.commentcount) AS owned_total_comments,
        SUM(p.favoritecount) AS owned_total_favorites
    FROM posts p
    JOIN users u ON p.owneruserid = u.id
    GROUP BY u.id
),
editor_stats AS (
    SELECT
        u.id AS user_id,
        COUNT(p.id) AS edited_post_count,
        SUM(p.score) AS edited_total_score,
        AVG(p.score) AS edited_avg_score
    FROM posts p
    JOIN users u ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
actor_stats AS (
    SELECT
        u.id AS user_id,
        COUNT(ph.id) AS action_count,
        COUNT(DISTINCT ph.postid) AS distinct_posts_acted_on,
        MIN(ph.creationdate) AS first_action_date,
        MAX(ph.creationdate) AS last_action_date
    FROM posthistory ph
    JOIN users u ON ph.userid = u.id
    GROUP BY u.id
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(os.owned_post_count, 0) AS owned_post_count,
    COALESCE(es.edited_post_count, 0) AS edited_post_count,
    COALESCE(act.action_count, 0) AS action_count,
    COALESCE(os.owned_total_score, 0) AS owned_total_score,
    COALESCE(es.edited_total_score, 0) AS edited_total_score,
    COALESCE(os.owned_avg_score, 0) AS owned_avg_score,
    COALESCE(es.edited_avg_score, 0) AS edited_avg_score,
    COALESCE(os.owned_total_views, 0) AS owned_total_views,
    COALESCE(os.owned_total_answers, 0) AS owned_total_answers,
    COALESCE(os.owned_total_comments, 0) AS owned_total_comments,
    COALESCE(os.owned_total_favorites, 0) AS owned_total_favorites,
    COALESCE(act.distinct_posts_acted_on, 0) AS distinct_posts_acted_on,
    act.first_action_date,
    act.last_action_date
FROM users u
LEFT JOIN owner_stats os ON u.id = os.user_id
LEFT JOIN editor_stats es ON u.id = es.user_id
LEFT JOIN actor_stats act ON u.id = act.user_id
ORDER BY u.reputation DESC
LIMIT 100
