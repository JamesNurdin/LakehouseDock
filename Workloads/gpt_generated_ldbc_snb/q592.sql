WITH city_metrics AS (
  SELECT
    city.id AS city_id,
    city.name AS city_name,
    region.id AS region_id,
    region.name AS region_name,
    COUNT(DISTINCT per.id) AS num_persons,
    COUNT(DISTINCT c.id) AS num_comments,
    AVG(c.length) AS avg_comment_length,
    COUNT(DISTINCT plp.post_id) AS total_likes_given,
    COUNT(DISTINCT fhmp.forum_id) AS num_forums_member_of
  FROM person per
  LEFT JOIN place city ON per.location_city_id = city.id
  LEFT JOIN place region ON city.part_of_place_id = region.id
  LEFT JOIN comment c ON c.creator_person_id = per.id
  LEFT JOIN person_likes_post plp ON plp.person_id = per.id
  LEFT JOIN forum_has_member_person fhmp ON fhmp.person_id = per.id
  GROUP BY
    city.id,
    city.name,
    region.id,
    region.name
)
SELECT
  city_id,
  city_name,
  region_id,
  region_name,
  num_persons,
  num_comments,
  avg_comment_length,
  total_likes_given,
  num_forums_member_of
FROM city_metrics
ORDER BY num_persons DESC
LIMIT 20
