WITH likes AS (
  SELECT 
    person_id,
    post_id,
    creation_date
  FROM person_likes_post
),
posts_with_tags AS (
  SELECT 
    p.id AS post_id,
    p.length,
    p.location_country_id,
    p.creator_person_id,
    ph.tag_id
  FROM post p
  LEFT JOIN post_has_tag_tag ph ON p.id = ph.post_id
)
SELECT 
  co.id AS country_id,
  co.name AS country_name,
  creator.gender AS creator_gender,
  COUNT(*) AS total_likes,
  COUNT(DISTINCT likes.person_id) AS distinct_likers,
  AVG(posts_with_tags.length) AS avg_post_length,
  COUNT(DISTINCT posts_with_tags.tag_id) AS distinct_tags
FROM likes
JOIN posts_with_tags ON likes.post_id = posts_with_tags.post_id
JOIN place co ON posts_with_tags.location_country_id = co.id
JOIN person creator ON posts_with_tags.creator_person_id = creator.id
WHERE co.type = 'Country'
GROUP BY co.id, co.name, creator.gender
ORDER BY total_likes DESC
LIMIT 50
