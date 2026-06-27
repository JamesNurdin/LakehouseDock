WITH moderator_stats AS (
  SELECT
    p.id AS moderator_id,
    p.first_name,
    p.last_name,
    p.gender,
    COUNT(f.id) AS forum_count,
    MIN(f.creation_date) AS earliest_forum_date,
    MAX(f.creation_date) AS latest_forum_date,
    AVG(LENGTH(f.title)) AS avg_title_len,
    APPROX_PERCENTILE(LENGTH(f.title), 0.5) AS median_title_len
  FROM forum f
  JOIN person p ON f.moderator_person_id = p.id
  GROUP BY p.id, p.first_name, p.last_name, p.gender
)
SELECT
  moderator_id,
  first_name,
  last_name,
  gender,
  forum_count,
  earliest_forum_date,
  latest_forum_date,
  avg_title_len,
  median_title_len
FROM moderator_stats
ORDER BY forum_count DESC
LIMIT 10
