WITH posts_agg AS (
    SELECT owneruserid AS user_id,
           COUNT(*) AS post_count,
           COALESCE(SUM(score), 0) AS total_post_score
    FROM posts
    GROUP BY owneruserid
),
comments_agg AS (
    SELECT userid AS user_id,
           COUNT(*) AS comment_count,
           COALESCE(SUM(score), 0) AS total_comment_score
    FROM comments
    GROUP BY userid
),
votes_agg AS (
    SELECT userid AS user_id,
           COUNT(*) AS vote_cast_count
    FROM votes
    GROUP BY userid
),
badges_agg AS (
    SELECT userid AS user_id,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
posthistory_agg AS (
    SELECT userid AS user_id,
           COUNT(*) AS post_history_count
    FROM posthistory
    GROUP BY userid
),
tags_agg AS (
    SELECT p.owneruserid AS user_id,
           COALESCE(SUM(t.count), 0) AS tag_usage_sum
    FROM tags t
    JOIN posts p ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT
    u.id AS user_id,
    u.reputation,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.total_post_score, 0) / NULLIF(COALESCE(p.post_count, 0), 0) AS avg_post_score,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(c.total_comment_score, 0) AS total_comment_score,
    COALESCE(c.total_comment_score, 0) / NULLIF(COALESCE(c.comment_count, 0), 0) AS avg_comment_score,
    COALESCE(v.vote_cast_count, 0) AS vote_cast_count,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(ph.post_history_count, 0) AS post_history_count,
    COALESCE(tg.tag_usage_sum, 0) AS tag_usage_sum,
    (COALESCE(p.post_count, 0) + COALESCE(c.comment_count, 0) + COALESCE(v.vote_cast_count, 0) + COALESCE(b.badge_count, 0)) AS total_contributions
FROM users u
LEFT JOIN posts_agg p ON p.user_id = u.id
LEFT JOIN comments_agg c ON c.user_id = u.id
LEFT JOIN votes_agg v ON v.user_id = u.id
LEFT JOIN badges_agg b ON b.user_id = u.id
LEFT JOIN posthistory_agg ph ON ph.user_id = u.id
LEFT JOIN tags_agg tg ON tg.user_id = u.id
WHERE u.creationdate >= TIMESTAMP '2022-01-01 00:00:00 UTC'
  AND u.creationdate < TIMESTAMP '2023-01-01 00:00:00 UTC'
ORDER BY total_contributions DESC
LIMIT 10
