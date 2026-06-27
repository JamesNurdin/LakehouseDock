WITH post_agg AS (
    SELECT
        p.owneruserid AS owner_user_id,
        COUNT(*) AS total_posts,
        SUM(p.score) AS total_post_score
    FROM posts p
    GROUP BY p.owneruserid
),
comment_agg AS (
    SELECT
        p.owneruserid AS owner_user_id,
        COUNT(c.id) AS comment_count,
        AVG(c.score) AS avg_comment_score,
        COUNT(DISTINCT c.userid) AS distinct_commenters
    FROM comments c
    JOIN posts p ON c.postid = p.id
    GROUP BY p.owneruserid
),
edit_agg AS (
    SELECT
        p.owneruserid AS owner_user_id,
        COUNT(ph.id) AS edit_count
    FROM posthistory ph
    JOIN posts p ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(pa.total_posts, 0) AS total_posts_owned,
    COALESCE(pa.total_post_score, 0) AS total_post_score,
    COALESCE(pa.total_post_score, 0) / NULLIF(COALESCE(pa.total_posts, 0), 0) AS avg_post_score,
    COALESCE(ca.comment_count, 0) AS total_comments_on_owned_posts,
    COALESCE(ca.avg_comment_score, 0) AS avg_comment_score_on_owned_posts,
    COALESCE(ea.edit_count, 0) AS total_post_edits,
    COALESCE(ca.distinct_commenters, 0) AS distinct_commenters
FROM users u
LEFT JOIN post_agg pa ON u.id = pa.owner_user_id
LEFT JOIN comment_agg ca ON u.id = ca.owner_user_id
LEFT JOIN edit_agg ea ON u.id = ea.owner_user_id
ORDER BY total_posts_owned DESC
LIMIT 100
