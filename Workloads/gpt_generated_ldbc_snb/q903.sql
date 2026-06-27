SELECT
    ct.tag_id,
    COUNT(*) AS total_likes,
    COUNT(DISTINCT plc.person_id) AS unique_likers,
    AVG(c.length) AS avg_comment_length,
    SUM(CASE WHEN p.gender = 'male'   THEN 1 ELSE 0 END) AS male_likes,
    SUM(CASE WHEN p.gender = 'female' THEN 1 ELSE 0 END) AS female_likes,
    SUM(CASE WHEN p.gender NOT IN ('male', 'female') THEN 1 ELSE 0 END) AS other_gender_likes,
    CAST(SUM(CASE WHEN p.gender = 'male'   THEN 1 ELSE 0 END) AS double) / COUNT(*) AS male_like_ratio,
    CAST(SUM(CASE WHEN p.gender = 'female' THEN 1 ELSE 0 END) AS double) / COUNT(*) AS female_like_ratio
FROM comment c
JOIN comment_has_tag_tag ct
  ON ct.comment_id = c.id
JOIN person_likes_comment plc
  ON plc.comment_id = c.id
JOIN person p
  ON plc.person_id = p.id
WHERE c.creation_date >= '2023-01-01'
  AND c.creation_date < '2024-01-01'
GROUP BY ct.tag_id
ORDER BY total_likes DESC
LIMIT 10
