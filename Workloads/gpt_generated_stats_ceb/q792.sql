WITH posts_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        COALESCE(SUM(p.score), 0) AS total_post_score,
        AVG(p.score) AS avg_post_score,
        COALESCE(SUM(p.viewcount), 0) AS total_post_views
    FROM posts p
    GROUP BY p.owneruserid
),
comments_made_agg AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comments_made
    FROM comments c
    GROUP BY c.userid
),
comments_received_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS comments_received
    FROM posts p
    JOIN comments c
        ON c.postid = p.id
    GROUP BY p.owneruserid
),
votes_cast_agg AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS votes_cast
    FROM votes v
    GROUP BY v.userid
),
votes_received_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS votes_received
    FROM posts p
    JOIN votes v
        ON v.postid = p.id
    GROUP BY p.owneruserid
),
badges_agg AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
tags_used_agg AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS distinct_tags_used
    FROM posts p
    JOIN tags t
        ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    COALESCE(pag.post_count, 0) AS post_count,
    COALESCE(pag.total_post_score, 0) AS total_post_score,
    COALESCE(pag.avg_post_score, 0) AS avg_post_score,
    COALESCE(pag.total_post_views, 0) AS total_post_views,
    COALESCE(cma.comments_made, 0) AS comments_made,
    COALESCE(cra.comments_received, 0) AS comments_received,
    COALESCE(vca.votes_cast, 0) AS votes_cast,
    COALESCE(vra.votes_received, 0) AS votes_received,
    COALESCE(ba.badge_count, 0) AS badge_count,
    COALESCE(tua.distinct_tags_used, 0) AS distinct_tags_used
FROM users u
LEFT JOIN posts_agg pag
    ON pag.user_id = u.id
LEFT JOIN comments_made_agg cma
    ON cma.user_id = u.id
LEFT JOIN comments_received_agg cra
    ON cra.user_id = u.id
LEFT JOIN votes_cast_agg vca
    ON vca.user_id = u.id
LEFT JOIN votes_received_agg vra
    ON vra.user_id = u.id
LEFT JOIN badges_agg ba
    ON ba.user_id = u.id
LEFT JOIN tags_used_agg tua
    ON tua.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 10
