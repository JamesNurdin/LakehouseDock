WITH
user_base AS (
    SELECT
        id,
        reputation,
        upvotes,
        downvotes
    FROM users
),
post_agg AS (
    SELECT
        owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(score) AS total_post_score,
        SUM(viewcount) AS total_post_views
    FROM posts
    GROUP BY owneruserid
),
comment_agg AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS comment_count,
        SUM(score) AS total_comment_score
    FROM comments
    GROUP BY userid
),
vote_agg AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS vote_cast_count
    FROM votes
    GROUP BY userid
),
badge_agg AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
posthistory_agg AS (
    SELECT
        userid AS user_id,
        COUNT(*) AS post_history_count
    FROM posthistory
    GROUP BY userid
),
post_edit_agg AS (
    SELECT
        lasteditoruserid AS user_id,
        COUNT(*) AS post_edit_count
    FROM posts
    GROUP BY lasteditoruserid
),
postlink_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT pl.id) AS post_link_count
    FROM postlinks pl
    JOIN posts p ON pl.postid = p.id
    GROUP BY p.owneruserid
),
tag_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS tag_excerpt_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.upvotes,
    u.downvotes,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_post_views, 0) AS total_post_views,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(v.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.post_history_count, 0) AS post_history_count,
    COALESCE(pe.post_edit_count, 0) AS post_edit_count,
    COALESCE(pl.post_link_count, 0) AS post_link_count,
    COALESCE(t.tag_excerpt_count, 0) AS tag_excerpt_count,
    (u.upvotes - u.downvotes) AS net_upvotes,
    CASE WHEN COALESCE(p.post_count, 0) > 0 THEN COALESCE(p.total_post_score, 0) * 1.0 / p.post_count END AS avg_post_score,
    CASE WHEN COALESCE(c.comment_count, 0) > 0 THEN COALESCE(c.total_comment_score, 0) * 1.0 / c.comment_count END AS avg_comment_score
FROM user_base u
LEFT JOIN post_agg p ON p.user_id = u.id
LEFT JOIN comment_agg c ON c.user_id = u.id
LEFT JOIN vote_agg v ON v.user_id = u.id
LEFT JOIN badge_agg b ON b.user_id = u.id
LEFT JOIN posthistory_agg ph ON ph.user_id = u.id
LEFT JOIN post_edit_agg pe ON pe.user_id = u.id
LEFT JOIN postlink_agg pl ON pl.user_id = u.id
LEFT JOIN tag_agg t ON t.user_id = u.id
ORDER BY net_upvotes DESC
LIMIT 100
