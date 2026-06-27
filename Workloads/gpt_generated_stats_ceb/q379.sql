WITH user_posts AS (
    SELECT owneruserid,
           COUNT(*) AS post_count,
           SUM(score) AS post_score_sum,
           AVG(score) AS post_score_avg
    FROM posts
    GROUP BY owneruserid
),
user_comments AS (
    SELECT userid,
           COUNT(*) AS comment_count,
           SUM(score) AS comment_score_sum
    FROM comments
    GROUP BY userid
),
user_votes AS (
    SELECT userid,
           COUNT(*) AS vote_count
    FROM votes
    GROUP BY userid
),
user_badges AS (
    SELECT userid,
           COUNT(*) AS badge_count
    FROM badges
    GROUP BY userid
),
user_tags AS (
    SELECT p.owneruserid,
           COUNT(DISTINCT t.id) AS tag_count
    FROM posts p
    JOIN tags t ON t.excerptpostid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COALESCE(p.post_count, 0) AS total_posts,
       COALESCE(p.post_score_sum, 0) AS total_post_score,
       COALESCE(p.post_score_avg, 0) AS avg_post_score,
       COALESCE(c.comment_count, 0) AS total_comments,
       COALESCE(c.comment_score_sum, 0) AS total_comment_score,
       COALESCE(v.vote_count, 0) AS total_votes,
       COALESCE(b.badge_count, 0) AS total_badges,
       COALESCE(tg.tag_count, 0) AS total_tags,
       (COALESCE(p.post_count, 0) * 5
        + COALESCE(c.comment_count, 0) * 2
        + COALESCE(v.vote_count, 0) * 1
        + COALESCE(b.badge_count, 0) * 3
        + COALESCE(tg.tag_count, 0) * 1) AS activity_score,
       ROW_NUMBER() OVER (
           ORDER BY (COALESCE(p.post_count, 0) * 5
                     + COALESCE(c.comment_count, 0) * 2
                     + COALESCE(v.vote_count, 0) * 1
                     + COALESCE(b.badge_count, 0) * 3
                     + COALESCE(tg.tag_count, 0) * 1) DESC
       ) AS activity_rank
FROM users u
LEFT JOIN user_posts p      ON p.owneruserid = u.id
LEFT JOIN user_comments c   ON c.userid = u.id
LEFT JOIN user_votes v      ON v.userid = u.id
LEFT JOIN user_badges b     ON b.userid = u.id
LEFT JOIN user_tags tg      ON tg.owneruserid = u.id
ORDER BY activity_score DESC
LIMIT 10
