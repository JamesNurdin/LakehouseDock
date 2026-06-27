WITH comment_likes AS (
    SELECT
        comment_id,
        COUNT(*) AS like_cnt
    FROM person_likes_comment
    GROUP BY comment_id
)
SELECT
    t.name AS tag_name,
    p.name AS country_name,
    COUNT(DISTINCT c.id) AS num_comments,
    COALESCE(SUM(cl.like_cnt), 0) AS total_likes,
    AVG(c.length) AS avg_comment_length,
    COUNT(DISTINCT creator.id) AS num_creators
FROM comment c
JOIN comment_has_tag_tag ct
  ON ct.comment_id = c.id
JOIN tag t
  ON t.id = ct.tag_id
LEFT JOIN comment_likes cl
  ON cl.comment_id = c.id
JOIN place p
  ON p.id = c.location_country_id
JOIN person creator
  ON creator.id = c.creator_person_id
GROUP BY t.name, p.name
ORDER BY total_likes DESC
LIMIT 20
