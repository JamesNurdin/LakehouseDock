WITH badge_agg AS (
    SELECT b.userid AS user_id,
           COUNT(*) AS badge_count
    FROM badges b
    GROUP BY b.userid
),
post_agg AS (
    SELECT p.owneruserid AS user_id,
           COUNT(*) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COUNT(DISTINCT t.id) AS tag_count
    FROM posts p
    LEFT JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
),
comment_agg AS (
    SELECT c.userid AS user_id,
           COUNT(*) AS comment_count,
           COALESCE(SUM(c.score), 0) AS total_comment_score
    FROM comments c
    GROUP BY c.userid
),
vote_agg AS (
    SELECT v.userid AS user_id,
           COUNT(*) AS vote_cast_count,
           COALESCE(SUM(v.votetypeid), 0) AS total_vote_type_sum
    FROM votes v
    GROUP BY v.userid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(b.badge_count, 0) AS badge_count,
       COALESCE(p.post_count, 0) AS post_count,
       COALESCE(p.total_post_score, 0) AS total_post_score,
       COALESCE(p.tag_count, 0) AS tag_count,
       COALESCE(c.comment_count, 0) AS comment_count,
       COALESCE(c.total_comment_score, 0) AS total_comment_score,
       COALESCE(v.vote_cast_count, 0) AS vote_cast_count,
       COALESCE(v.total_vote_type_sum, 0) AS total_vote_type_sum
FROM users u
LEFT JOIN badge_agg b ON b.user_id = u.id
LEFT JOIN post_agg p ON p.user_id = u.id
LEFT JOIN comment_agg c ON c.user_id = u.id
LEFT JOIN vote_agg v ON v.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 10
