WITH badge_counts AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
owned_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS owned_post_count,
        SUM(p.score) AS owned_score_sum,
        AVG(p.score) AS owned_score_avg,
        SUM(p.viewcount) AS owned_viewcount_sum,
        SUM(p.favoritecount) AS owned_favoritecount_sum
    FROM posts p
    GROUP BY p.owneruserid
),
edited_posts AS (
    SELECT
        p.lasteditoruserid AS user_id,
        COUNT(*) AS edited_post_count,
        SUM(p.score) AS edited_score_sum,
        AVG(p.score) AS edited_score_avg
    FROM posts p
    GROUP BY p.lasteditoruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.upvotes,
    u.downvotes,
    COALESCE(bc.badge_count, 0)               AS badge_count,
    COALESCE(op.owned_post_count, 0)          AS owned_post_count,
    COALESCE(op.owned_score_sum, 0)           AS owned_score_sum,
    COALESCE(op.owned_score_avg, 0)           AS owned_score_avg,
    COALESCE(op.owned_viewcount_sum, 0)       AS owned_viewcount_sum,
    COALESCE(op.owned_favoritecount_sum, 0)   AS owned_favoritecount_sum,
    COALESCE(ep.edited_post_count, 0)         AS edited_post_count,
    COALESCE(ep.edited_score_sum, 0)          AS edited_score_sum,
    COALESCE(ep.edited_score_avg, 0)          AS edited_score_avg,
    CASE
        WHEN u.downvotes = 0 THEN NULL
        ELSE CAST(u.upvotes AS double) / u.downvotes
    END                                        AS upvote_downvote_ratio
FROM users u
LEFT JOIN badge_counts bc   ON bc.user_id = u.id
LEFT JOIN owned_posts op    ON op.user_id = u.id
LEFT JOIN edited_posts ep   ON ep.user_id = u.id
ORDER BY badge_count DESC, owned_post_count DESC
LIMIT 100
