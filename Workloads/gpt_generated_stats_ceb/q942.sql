WITH user_base AS (
    SELECT
        u.id AS user_id,
        u.reputation
    FROM users u
),
posts_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT p.id) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        COALESCE(AVG(p.score), 0) AS avg_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_post_views
    FROM posts p
    GROUP BY p.owneruserid
),
posts_edited_stats AS (
    SELECT
        p.lasteditoruserid AS user_id,
        COUNT(DISTINCT p.id) AS edited_post_count
    FROM posts p
    WHERE p.lasteditoruserid IS NOT NULL
    GROUP BY p.lasteditoruserid
),
comments_stats AS (
    SELECT
        c.userid AS user_id,
        COUNT(DISTINCT c.id) AS comment_count
    FROM comments c
    GROUP BY c.userid
),
votes_cast_stats AS (
    SELECT
        v.userid AS user_id,
        COUNT(DISTINCT v.id) AS votes_cast_count
    FROM votes v
    GROUP BY v.userid
),
votes_received_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT v.id) AS votes_received_count
    FROM posts p
    JOIN votes v ON v.postid = p.id
    GROUP BY p.owneruserid
),
badges_stats AS (
    SELECT
        b.userid AS user_id,
        COUNT(DISTINCT b.id) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
posthistory_stats AS (
    SELECT
        ph.userid AS user_id,
        COUNT(DISTINCT ph.id) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
),
tags_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)

SELECT
    ub.user_id,
    ub.reputation,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(pes.edited_post_count, 0) AS edited_post_count,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(vcs.votes_cast_count, 0) AS votes_cast_count,
    COALESCE(vrs.votes_received_count, 0) AS votes_received_count,
    COALESCE(bs.badge_count, 0) AS badge_count,
    COALESCE(phs.posthistory_count, 0) AS posthistory_count,
    COALESCE(ts.tag_count, 0) AS tag_count,
    COALESCE(ps.total_post_score, 0) AS total_post_score,
    COALESCE(ps.avg_post_score, 0) AS avg_post_score,
    COALESCE(ps.total_post_views, 0) AS total_post_views
FROM user_base ub
LEFT JOIN posts_stats ps ON ps.user_id = ub.user_id
LEFT JOIN posts_edited_stats pes ON pes.user_id = ub.user_id
LEFT JOIN comments_stats cs ON cs.user_id = ub.user_id
LEFT JOIN votes_cast_stats vcs ON vcs.user_id = ub.user_id
LEFT JOIN votes_received_stats vrs ON vrs.user_id = ub.user_id
LEFT JOIN badges_stats bs ON bs.user_id = ub.user_id
LEFT JOIN posthistory_stats phs ON phs.user_id = ub.user_id
LEFT JOIN tags_stats ts ON ts.user_id = ub.user_id
ORDER BY ub.reputation DESC
LIMIT 20
