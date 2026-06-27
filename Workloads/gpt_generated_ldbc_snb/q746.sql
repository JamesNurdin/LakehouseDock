WITH person_info AS (
  SELECT
    id,
    first_name,
    last_name,
    gender,
    location_city_id
  FROM person
),

city_info AS (
  SELECT
    id,
    name AS city_name
  FROM place
),

comments_created AS (
  SELECT
    creator_person_id,
    COUNT(*) AS comment_count,
    SUM(length) AS total_comment_length,
    AVG(length) AS avg_comment_length
  FROM comment
  GROUP BY creator_person_id
),

posts_created AS (
  SELECT
    creator_person_id,
    COUNT(*) AS post_count,
    SUM(length) AS total_post_length,
    AVG(length) AS avg_post_length
  FROM post
  GROUP BY creator_person_id
),

likes_given_comment AS (
  SELECT
    person_id,
    COUNT(*) AS likes_given_comment_count
  FROM person_likes_comment
  GROUP BY person_id
),

likes_given_post AS (
  SELECT
    person_id,
    COUNT(*) AS likes_given_post_count
  FROM person_likes_post
  GROUP BY person_id
),

likes_received_comment AS (
  SELECT
    c.creator_person_id,
    COUNT(*) AS likes_received_comment_count
  FROM person_likes_comment plc
  JOIN comment c ON plc.comment_id = c.id
  GROUP BY c.creator_person_id
),

likes_received_post AS (
  SELECT
    po.creator_person_id,
    COUNT(*) AS likes_received_post_count
  FROM person_likes_post plp
  JOIN post po ON plp.post_id = po.id
  GROUP BY po.creator_person_id
)

SELECT
  pi.id AS person_id,
  pi.first_name,
  pi.last_name,
  pi.gender,
  ci.city_name,
  COALESCE(cc.comment_count, 0) AS comment_count,
  COALESCE(cc.total_comment_length, 0) AS total_comment_length,
  COALESCE(cc.avg_comment_length, 0) AS avg_comment_length,
  COALESCE(pc.post_count, 0) AS post_count,
  COALESCE(pc.total_post_length, 0) AS total_post_length,
  COALESCE(pc.avg_post_length, 0) AS avg_post_length,
  COALESCE(lgc.likes_given_comment_count, 0) AS likes_given_comment_count,
  COALESCE(lgp.likes_given_post_count, 0) AS likes_given_post_count,
  COALESCE(lrc.likes_received_comment_count, 0) AS likes_received_comment_count,
  COALESCE(lrp.likes_received_post_count, 0) AS likes_received_post_count,
  COALESCE(lgc.likes_given_comment_count, 0) + COALESCE(lgp.likes_given_post_count, 0) AS total_likes_given,
  COALESCE(lrc.likes_received_comment_count, 0) + COALESCE(lrp.likes_received_post_count, 0) AS total_likes_received
FROM person_info pi
LEFT JOIN city_info ci ON pi.location_city_id = ci.id
LEFT JOIN comments_created cc ON pi.id = cc.creator_person_id
LEFT JOIN posts_created pc ON pi.id = pc.creator_person_id
LEFT JOIN likes_given_comment lgc ON pi.id = lgc.person_id
LEFT JOIN likes_given_post lgp ON pi.id = lgp.person_id
LEFT JOIN likes_received_comment lrc ON pi.id = lrc.creator_person_id
LEFT JOIN likes_received_post lrp ON pi.id = lrp.creator_person_id
ORDER BY total_likes_received DESC
LIMIT 10
