WITH
    badge_counts AS (
        SELECT
            userid,
            COUNT(*) AS badge_count
        FROM badges
        GROUP BY userid
    ),
    post_stats AS (
        SELECT
            owneruserid,
            COUNT(*) AS post_count,
            SUM(score) AS total_post_score,
            AVG(score) AS avg_post_score
        FROM posts
        GROUP BY owneruserid
    ),
    comment_counts AS (
        SELECT
            userid,
            COUNT(*) AS comment_count
        FROM comments
        GROUP BY userid
    ),
    vote_counts AS (
        SELECT
            userid,
            COUNT(*) AS vote_count
        FROM votes
        GROUP BY userid
    ),
    tag_counts AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS tag_excerpts,
            SUM(t."count") AS tag_total_count
        FROM tags t
        JOIN posts p ON t.excerptpostid = p.id
        GROUP BY p.owneruserid
    ),
    postlink_counts AS (
        SELECT
            p.owneruserid,
            COUNT(*) AS link_count
        FROM postlinks pl
        JOIN posts p ON pl.postid = p.id
        GROUP BY p.owneruserid
    )
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(bc.badge_count, 0) AS badge_count,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.total_post_score, 0) AS total_post_score,
    COALESCE(ps.avg_post_score, 0) AS avg_post_score,
    COALESCE(cc.comment_count, 0) AS comment_count,
    COALESCE(vc.vote_count, 0) AS vote_count,
    COALESCE(tc.tag_excerpts, 0) AS tag_excerpts,
    COALESCE(tc.tag_total_count, 0) AS tag_total_count,
    COALESCE(plc.link_count, 0) AS link_count,
    (COALESCE(bc.badge_count, 0) * 1.0) / NULLIF(COALESCE(ps.post_count, 0), 0) AS badge_per_post
FROM users u
LEFT JOIN badge_counts bc ON bc.userid = u.id
LEFT JOIN post_stats ps ON ps.owneruserid = u.id
LEFT JOIN comment_counts cc ON cc.userid = u.id
LEFT JOIN vote_counts vc ON vc.userid = u.id
LEFT JOIN tag_counts tc ON tc.owneruserid = u.id
LEFT JOIN postlink_counts plc ON plc.owneruserid = u.id
ORDER BY u.reputation DESC
LIMIT 10
