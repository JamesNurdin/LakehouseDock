WITH post_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        COALESCE(SUM(p.score), 0) AS post_score_sum,
        COALESCE(SUM(p.viewcount), 0) AS post_viewcount_sum
    FROM posts p
    GROUP BY p.owneruserid
),
comment_stats AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count,
        COALESCE(SUM(c.score), 0) AS comment_score_sum
    FROM comments c
    GROUP BY c.userid
),
vote_stats AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS vote_cast_count
    FROM votes v
    GROUP BY v.userid
),
badge_stats AS (
    SELECT
        b.userid AS user_id,
        COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
posthistory_stats AS (
    SELECT
        ph.userid AS user_id,
        COUNT(*) AS posthistory_count
    FROM posthistory ph
    GROUP BY ph.userid
),
postlink_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT pl.id) AS postlink_count
    FROM posts p
    JOIN postlinks pl
        ON pl.postid = p.id OR pl.relatedpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.post_score_sum, 0) AS post_score_sum,
    COALESCE(ps.post_viewcount_sum, 0) AS post_viewcount_sum,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(vs.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(bs.badge_count, 0) AS badge_count,
    COALESCE(phs.posthistory_count, 0) AS posthistory_count,
    COALESCE(pls.postlink_count, 0) AS postlink_count
FROM users u
LEFT JOIN post_stats ps      ON ps.user_id = u.id
LEFT JOIN comment_stats cs   ON cs.user_id = u.id
LEFT JOIN vote_stats vs      ON vs.user_id = u.id
LEFT JOIN badge_stats bs     ON bs.user_id = u.id
LEFT JOIN posthistory_stats phs ON phs.user_id = u.id
LEFT JOIN postlink_stats pls ON pls.user_id = u.id
ORDER BY u.reputation DESC
LIMIT 100
