-- User activity summary: badge count, posts owned, total/average scores, view stats,
-- edit count, post‑history actions, and ranking by total post score.
WITH user_badges AS (
    SELECT u.id AS user_id,
           COUNT(b.id) AS badge_count
    FROM users u
    LEFT JOIN badges b
      ON b.userid = u.id
    GROUP BY u.id
),
user_posts AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS post_count,
           COALESCE(SUM(p.score), 0) AS total_post_score,
           COALESCE(AVG(p.score), 0) AS avg_post_score,
           COALESCE(SUM(p.viewcount), 0) AS total_viewcount
    FROM users u
    LEFT JOIN posts p
      ON p.owneruserid = u.id
    GROUP BY u.id
),
user_edits AS (
    SELECT u.id AS user_id,
           COUNT(p.id) AS edit_count
    FROM users u
    LEFT JOIN posts p
      ON p.lasteditoruserid = u.id
    GROUP BY u.id
),
user_history AS (
    SELECT u.id AS user_id,
           COUNT(ph.id) AS history_count
    FROM users u
    LEFT JOIN posthistory ph
      ON ph.userid = u.id
    GROUP BY u.id
)
SELECT
    u.id,
    u.reputation,
    COALESCE(b.badge_count, 0) AS badge_count,
    COALESCE(p.post_count, 0) AS post_count,
    COALESCE(p.total_post_score, 0) AS total_post_score,
    COALESCE(p.avg_post_score, 0) AS avg_post_score,
    COALESCE(p.total_viewcount, 0) AS total_viewcount,
    CASE
        WHEN COALESCE(p.post_count, 0) > 0
        THEN CAST(COALESCE(p.total_viewcount, 0) AS double) / p.post_count
        ELSE 0
    END AS avg_views_per_post,
    COALESCE(e.edit_count, 0) AS edit_count,
    COALESCE(h.history_count, 0) AS history_count,
    RANK() OVER (ORDER BY COALESCE(p.total_post_score, 0) DESC) AS total_score_rank
FROM users u
LEFT JOIN user_badges b
  ON b.user_id = u.id
LEFT JOIN user_posts p
  ON p.user_id = u.id
LEFT JOIN user_edits e
  ON e.user_id = u.id
LEFT JOIN user_history h
  ON h.user_id = u.id
ORDER BY total_post_score DESC
LIMIT 100
