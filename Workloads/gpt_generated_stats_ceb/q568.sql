WITH post_stats AS (
    SELECT owneruserid,
           COUNT(*) AS post_count,
           COALESCE(SUM(score), 0) AS total_post_score,
           COALESCE(AVG(score), 0) AS avg_post_score
    FROM posts
    GROUP BY owneruserid
),
comment_stats AS (
    SELECT userid,
           COUNT(*) AS comment_count
    FROM comments
    GROUP BY userid
),
vote_stats AS (
    SELECT userid,
           COUNT(*) AS vote_cast_count
    FROM votes
    GROUP BY userid
),
badge_stats AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
posthistory_stats AS (
    SELECT userid,
           COUNT(*) AS post_history_count
    FROM posthistory
    GROUP BY userid
),
tag_stats AS (
    SELECT p.owneruserid,
           COUNT(DISTINCT t.id) AS distinct_tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(ps.post_count, 0) AS post_count,
    COALESCE(ps.total_post_score, 0) AS total_post_score,
    COALESCE(ps.avg_post_score, 0) AS avg_post_score,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(vs.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(bs.badge_count, 0) AS badge_count,
    COALESCE(phs.post_history_count, 0) AS post_history_count,
    COALESCE(ts.distinct_tag_count, 0) AS distinct_tag_count
FROM users u
LEFT JOIN post_stats ps ON ps.owneruserid = u.id
LEFT JOIN comment_stats cs ON cs.userid = u.id
LEFT JOIN vote_stats vs ON vs.userid = u.id
LEFT JOIN badge_stats bs ON bs.userid = u.id
LEFT JOIN posthistory_stats phs ON phs.userid = u.id
LEFT JOIN tag_stats ts ON ts.owneruserid = u.id
ORDER BY total_post_score DESC
LIMIT 100
