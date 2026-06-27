WITH post_actions AS (
    SELECT p.id AS post_id,
           COUNT(ph.id) AS action_count
    FROM posts p
    JOIN posthistory ph
      ON ph.posthistorytypeid = p.id
    GROUP BY p.id
),
owner_distinct_action_users AS (
    SELECT p.owneruserid AS owner_user_id,
           COUNT(DISTINCT ph.userid) AS distinct_user_count
    FROM posts p
    JOIN posthistory ph
      ON ph.posthistorytypeid = p.id
    GROUP BY p.owneruserid
)
SELECT u.id AS user_id,
       u.reputation,
       COUNT(p.id) AS post_count,
       COALESCE(SUM(p.score), 0) AS total_score,
       COALESCE(AVG(p.score), 0) AS avg_score,
       COALESCE(SUM(pa.action_count), 0) AS total_actions_on_posts,
       COALESCE(MAX(odau.distinct_user_count), 0) AS distinct_action_users
FROM users u
LEFT JOIN posts p
  ON p.owneruserid = u.id
LEFT JOIN post_actions pa
  ON pa.post_id = p.id
LEFT JOIN owner_distinct_action_users odau
  ON odau.owner_user_id = u.id
GROUP BY u.id, u.reputation
ORDER BY total_actions_on_posts DESC
LIMIT 100
