/*
  Analytical query: Top 20 users by reputation with activity metrics
  – owned posts, comments, votes, badges, edits, and tag excerpts authored
  – average post score and total post views for owned posts
  – total activity score (posts + comments + votes)
*/
WITH user_posts AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS owned_posts,
        AVG(p.score) AS avg_post_score,
        SUM(p.viewcount) AS total_post_views
    FROM posts p
    GROUP BY p.owneruserid
),
user_comments AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count
    FROM comments c
    GROUP BY c.userid
),
user_votes AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS vote_count
    FROM votes v
    GROUP BY v.userid
),
user_badges AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
user_edits AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS edit_count
    FROM posthistory ph
    GROUP BY ph.userid
),
user_tags AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS tag_excerpt_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(up.owned_posts, 0)      AS owned_posts,
    COALESCE(uc.comment_count, 0)    AS comment_count,
    COALESCE(uv.vote_count, 0)       AS vote_count,
    COALESCE(ub.badge_count, 0)      AS badge_count,
    COALESCE(ue.edit_count, 0)       AS edit_count,
    COALESCE(ut.tag_excerpt_count, 0) AS tag_excerpt_count,
    COALESCE(up.avg_post_score, 0)   AS avg_post_score,
    COALESCE(up.total_post_views, 0) AS total_post_views,
    (COALESCE(up.owned_posts, 0) + COALESCE(uc.comment_count, 0) + COALESCE(uv.vote_count, 0)) AS total_activity
FROM users u
LEFT JOIN user_posts   up ON up.user_id = u.id
LEFT JOIN user_comments uc ON uc.user_id = u.id
LEFT JOIN user_votes   uv ON uv.user_id = u.id
LEFT JOIN user_badges  ub ON ub.user_id = u.id
LEFT JOIN user_edits   ue ON ue.user_id = u.id
LEFT JOIN user_tags    ut ON ut.user_id = u.id
WHERE COALESCE(up.owned_posts, 0) > 0
ORDER BY u.reputation DESC
LIMIT 20
