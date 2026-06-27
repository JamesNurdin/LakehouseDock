WITH post_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(*) AS post_count,
        SUM(p.score) AS post_score_sum,
        MAX(p.creationdate) AS latest_post_date
    FROM posts p
    GROUP BY p.owneruserid
),
comment_stats AS (
    SELECT
        c.userid AS user_id,
        COUNT(*) AS comment_count,
        SUM(c.score) AS comment_score_sum,
        MAX(c.creationdate) AS latest_comment_date
    FROM comments c
    GROUP BY c.userid
),
vote_stats AS (
    SELECT
        v.userid AS user_id,
        COUNT(*) AS vote_count,
        SUM(v.votetypeid) AS vote_type_sum,
        MAX(v.creationdate) AS latest_vote_date
    FROM votes v
    GROUP BY v.userid
),
tag_stats AS (
    SELECT
        p.owneruserid AS user_id,
        COUNT(DISTINCT t.id) AS tag_count
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.post_score_sum, 0) AS post_score_sum,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.comment_score_sum, 0) AS comment_score_sum,
    COALESCE(v.vote_count, 0) AS vote_count,
    COALESCE(v.vote_type_sum, 0) AS vote_type_sum,
    COALESCE(t.tag_count, 0) AS tag_count,
    (COALESCE(p.post_score_sum, 0) + COALESCE(c.comment_score_sum, 0)) AS total_contribution_score,
    GREATEST(
        COALESCE(p.latest_post_date, TIMESTAMP '1970-01-01 00:00:00 UTC'),
        COALESCE(c.latest_comment_date, TIMESTAMP '1970-01-01 00:00:00 UTC'),
        COALESCE(v.latest_vote_date, TIMESTAMP '1970-01-01 00:00:00 UTC')
    ) AS most_recent_activity
FROM users u
LEFT JOIN post_stats p ON p.user_id = u.id
LEFT JOIN comment_stats c ON c.user_id = u.id
LEFT JOIN vote_stats v ON v.user_id = u.id
LEFT JOIN tag_stats t ON t.user_id = u.id
ORDER BY total_contribution_score DESC
LIMIT 20
