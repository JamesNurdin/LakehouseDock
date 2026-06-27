WITH post_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS posts_authored,
        SUM(p.score) AS total_score,
        AVG(p.score) AS avg_score,
        SUM(p.viewcount) AS total_views,
        SUM(p.answercount) AS total_answers,
        SUM(p.commentcount) AS total_comments,
        SUM(p.favoritecount) AS total_favorites
    FROM posts p
    GROUP BY p.owneruserid
),

tag_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(t.id) AS total_tags,
        COALESCE(SUM(t.count), 0) AS sum_tag_counts
    FROM posts p
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),

edit_agg AS (
    SELECT
        p.lasteditoruserid AS user_id,
        COUNT(*) AS posts_edited
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(pa.posts_authored, 0) AS posts_authored,
    COALESCE(ea.posts_edited, 0) AS posts_edited,
    COALESCE(pa.total_score, 0) AS total_score,
    COALESCE(pa.avg_score, 0) AS avg_score,
    COALESCE(pa.total_views, 0) AS total_views,
    COALESCE(pa.total_answers, 0) AS total_answers,
    COALESCE(pa.total_comments, 0) AS total_comments,
    COALESCE(pa.total_favorites, 0) AS total_favorites,
    COALESCE(ta.total_tags, 0) AS total_tags,
    COALESCE(ta.sum_tag_counts, 0) AS sum_tag_counts
FROM users u
LEFT JOIN post_agg pa ON pa.user_id = u.id
LEFT JOIN edit_agg ea ON ea.user_id = u.id
LEFT JOIN tag_agg ta ON ta.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
