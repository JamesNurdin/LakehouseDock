WITH owned AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS owned_posts,
        SUM(p.score) AS total_score,
        AVG(p.score) AS avg_score,
        SUM(p.viewcount) AS total_views,
        SUM(p.answercount) AS total_answers,
        SUM(p.commentcount) AS total_comments,
        SUM(p.favoritecount) AS total_favorites,
        COUNT(ph.id) AS total_history_events_on_owned_posts
    FROM posts p
    LEFT JOIN posthistory ph
        ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
),
edited AS (
    SELECT
        p.lasteditoruserid AS user_id,
        COUNT(*) AS edited_posts,
        SUM(p.score) AS total_edited_score,
        AVG(p.score) AS avg_edited_score
    FROM posts p
    GROUP BY p.lasteditoruserid
),
history_by_user AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS history_actions_performed,
        COUNT(DISTINCT ph.postid) AS distinct_posts_acted_on
    FROM posthistory ph
    GROUP BY ph.userid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(o.owned_posts, 0) AS owned_posts,
    COALESCE(o.total_score, 0) AS total_owned_score,
    COALESCE(o.avg_score, 0) AS avg_owned_score,
    COALESCE(o.total_views, 0) AS total_owned_views,
    COALESCE(o.total_answers, 0) AS total_owned_answers,
    COALESCE(o.total_comments, 0) AS total_owned_comments,
    COALESCE(o.total_favorites, 0) AS total_owned_favorites,
    COALESCE(o.total_history_events_on_owned_posts, 0) AS total_history_on_owned_posts,
    COALESCE(e.edited_posts, 0) AS edited_posts,
    COALESCE(e.total_edited_score, 0) AS total_edited_score,
    COALESCE(e.avg_edited_score, 0) AS avg_edited_score,
    COALESCE(h.history_actions_performed, 0) AS history_actions_performed,
    COALESCE(h.distinct_posts_acted_on, 0) AS distinct_posts_acted_on
FROM users u
LEFT JOIN owned o
    ON o.user_id = u.id
LEFT JOIN edited e
    ON e.user_id = u.id
LEFT JOIN history_by_user h
    ON h.user_id = u.id
ORDER BY total_owned_score DESC
LIMIT 100
