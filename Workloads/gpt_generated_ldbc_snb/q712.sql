SELECT
    org.type AS org_type,
    org.name AS org_name,
    comment_country.name AS comment_country_name,
    COUNT(c.id) AS comment_count,
    AVG(c.length) AS avg_comment_length
FROM comment c
JOIN post p
  ON c.parent_post_id = p.id
JOIN person post_creator
  ON p.creator_person_id = post_creator.id
JOIN place post_creator_city
  ON post_creator.location_city_id = post_creator_city.id
JOIN organisation org
  ON org.location_place_id = post_creator_city.id
JOIN place comment_country
  ON c.location_country_id = comment_country.id
GROUP BY org.type, org.name, comment_country.name
ORDER BY comment_count DESC
LIMIT 10
