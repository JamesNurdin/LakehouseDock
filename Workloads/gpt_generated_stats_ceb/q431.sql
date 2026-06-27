WITH owned_stats AS (
    SELECT
        p.owneruserid AS user_id,
        u.reputation AS reputation,
        COUNT(*) AS owned_post_count,
        SUM(p.score) AS owned_total_score,
        SUM(p.viewcount) AS owned_total_viewcount,
        AVG(p.viewcount) AS owned_avg_viewcount,
        SUM(p.favoritecount) AS owned_total_favoritecount
    FROM posts p
    JOIN users u
        ON p.owneruserid = u.id
    GROUP BY p.owneruserid, u.reputation
),
edited_stats AS (
    SELECT
        p.lasteditoruserid AS user_id,
        u.reputation AS reputation,
        COUNT(*) AS edited_post_count,
        SUM(p.score) AS edited_total_score,
        SUM(p.viewcount) AS edited_total_viewcount,
        AVG(p.viewcount) AS edited_avg_viewcount,
        SUM(p.favoritecount) AS edited_total_favoritecount
    FROM posts p
    JOIN users u
        ON p.lasteditoruserid = u.id
    GROUP BY p.lasteditoruserid, u.reputation
),
combined AS (
    SELECT
        COALESCE(o.user_id, e.user_id) AS user_id,
        COALESCE(o.reputation, e.reputation) AS reputation,
        o.owned_post_count,
        o.owned_total_score,
        o.owned_total_viewcount,
        o.owned_avg_viewcount,
        o.owned_total_favoritecount,
        e.edited_post_count,
        e.edited_total_score,
        e.edited_total_viewcount,
        e.edited_avg_viewcount,
        e.edited_total_favoritecount
    FROM owned_stats o
    FULL OUTER JOIN edited_stats e
        ON o.user_id = e.user_id
)
SELECT
    user_id,
    reputation,
    owned_post_count,
    owned_total_score,
    owned_total_viewcount,
    owned_avg_viewcount,
    owned_total_favoritecount,
    CASE WHEN owned_total_viewcount > 0 THEN owned_total_favoritecount / owned_total_viewcount END AS owned_favorite_to_view_ratio,
    edited_post_count,
    edited_total_score,
    edited_total_viewcount,
    edited_avg_viewcount,
    edited_total_favoritecount,
    CASE WHEN edited_total_viewcount > 0 THEN edited_total_favoritecount / edited_total_viewcount END AS edited_favorite_to_view_ratio
FROM combined
ORDER BY user_id
