WITH
    user_posts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS post_count,
            COALESCE(SUM(p.score), 0) AS total_post_score,
            COALESCE(SUM(p.viewcount), 0) AS total_post_views
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
            COUNT(*) AS vote_cast_count
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
    user_posthistory AS (
        SELECT
            ph.userid AS user_id,
            COUNT(*) AS posthistory_count
        FROM posthistory ph
        GROUP BY ph.userid
    ),
    user_tag_excerpts AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS tag_excerpt_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    user_postlinks AS (
        SELECT
            p.owneruserid AS user_id,
            COUNT(*) AS postlink_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    u.creationdate,
    u.views,
    u.upvotes,
    u.downvotes,
    COALESCE(up.post_count, 0) AS post_count,
    COALESCE(up.total_post_score, 0) AS total_post_score,
    COALESCE(up.total_post_views, 0) AS total_post_views,
    COALESCE(uc.comment_count, 0) AS comment_count,
    COALESCE(uv.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(ub.badge_count, 0) AS badge_count,
    COALESCE(uph.posthistory_count, 0) AS posthistory_count,
    COALESCE(ute.tag_excerpt_count, 0) AS tag_excerpt_count,
    COALESCE(upl.postlink_count, 0) AS postlink_count,
    CASE WHEN COALESCE(up.post_count, 0) > 0 THEN COALESCE(up.total_post_score, 0) / up.post_count ELSE NULL END AS avg_post_score,
    CASE WHEN COALESCE(up.post_count, 0) > 0 THEN COALESCE(up.total_post_views, 0) / up.post_count ELSE NULL END AS avg_post_views
FROM users u
LEFT JOIN user_posts up   ON up.user_id   = u.id
LEFT JOIN user_comments uc ON uc.user_id   = u.id
LEFT JOIN user_votes uv   ON uv.user_id   = u.id
LEFT JOIN user_badges ub  ON ub.user_id   = u.id
LEFT JOIN user_posthistory uph ON uph.user_id = u.id
LEFT JOIN user_tag_excerpts ute ON ute.user_id = u.id
LEFT JOIN user_postlinks upl   ON upl.user_id = u.id
ORDER BY badge_count DESC, reputation DESC
LIMIT 100
