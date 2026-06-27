SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    COUNT(f.id) AS forum_count,
    MIN(f.creation_date) AS earliest_forum_creation,
    MAX(f.creation_date) AS latest_forum_creation
FROM forum AS f
JOIN person AS p
  ON f.moderator_person_id = p.id
GROUP BY p.id, p.first_name, p.last_name, p.gender
ORDER BY forum_count DESC
LIMIT 10
