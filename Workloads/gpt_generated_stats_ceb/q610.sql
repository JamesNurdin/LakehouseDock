WITH owned_posts AS (
    SELECT u.id AS user_id,
           COUNT(*) AS owned_post_count,
           COALESCE(SUM(p.score), 0) AS total_score,
           COALESCE(SUM(p.viewcount), 0) AS total_views,
           AVG(p.score) AS avg_score
    FROM users u
    JOIN posts p
      ON p.owneruserid = u.id
    GROUP BY u.id
),
history_entries AS (
    SELECT u.id AS user_id,
           COUNT(*) AS history_entry_count,
           COUNT(DISTINCT p.id) AS distinct_edited_post_count
    FROM users u
    JOIN posthistory ph
      ON ph.userid = u.id
    JOIN posts p
      ON ph.posthistorytypeid = p.id
    GROUP BY u.id
),
last_edits AS (
    SELECT u.id AS user_id,
           COUNT(*) AS last_edit_post_count
    FROM users u
    JOIN posts p
      ON p.lasteditoruserid = u.id
    GROUP BY u.id
)
SELECT u.id,
       u.reputation,
       COALESCE(op.owned_post_count, 0)               AS owned_post_count,
       COALESCE(op.total_score, 0)                    AS total_owned_score,
       COALESCE(op.total_views, 0)                    AS total_owned_views,
       COALESCE(op.avg_score, 0)                      AS avg_owned_score,
       COALESCE(he.history_entry_count, 0)           AS history_entry_count,
       COALESCE(he.distinct_edited_post_count, 0)    AS distinct_edited_post_count,
       COALESCE(le.last_edit_post_count, 0)          AS last_edit_post_count
FROM users u
LEFT JOIN owned_posts op   ON op.user_id = u.id
LEFT JOIN history_entries he ON he.user_id = u.id
LEFT JOIN last_edits le      ON le.user_id = u.id
ORDER BY total_owned_score DESC
LIMIT 100
