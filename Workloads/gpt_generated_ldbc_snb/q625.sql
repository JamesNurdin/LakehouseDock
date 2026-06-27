WITH
  posts_by_person AS (
    SELECT creator_person_id AS person_id,
           COUNT(*) AS post_count
    FROM post
    GROUP BY creator_person_id
  ),
  comments_by_person AS (
    SELECT creator_person_id AS person_id,
           COUNT(*) AS comment_count
    FROM comment
    GROUP BY creator_person_id
  ),
  likes_given_by_person AS (
    SELECT person_id,
           COUNT(*) AS likes_given_count
    FROM (
      SELECT person_id FROM person_likes_post
      UNION ALL
      SELECT person_id FROM person_likes_comment
    ) t
    GROUP BY person_id
  ),
  likes_received_by_person AS (
    SELECT person_id,
           SUM(likes_received) AS likes_received_count
    FROM (
      SELECT p.creator_person_id AS person_id,
             COUNT(*) AS likes_received
      FROM post p
      JOIN person_likes_post plp ON plp.post_id = p.id
      GROUP BY p.creator_person_id
      UNION ALL
      SELECT c.creator_person_id AS person_id,
             COUNT(*) AS likes_received
      FROM comment c
      JOIN person_likes_comment plc ON plc.comment_id = c.id
      GROUP BY c.creator_person_id
    ) t
    GROUP BY person_id
  ),
  friends_count_by_person AS (
    SELECT person_id,
           COUNT(DISTINCT friend_id) AS friend_count
    FROM (
      SELECT person1_id AS person_id,
             person2_id AS friend_id
      FROM person_knows_person
      UNION ALL
      SELECT person2_id AS person_id,
             person1_id AS friend_id
      FROM person_knows_person
    ) f
    GROUP BY person_id
  )
SELECT
  p.id AS person_id,
  p.first_name,
  p.last_name,
  p.gender,
  p.birthday,
  COALESCE(pb.post_count, 0) AS total_posts,
  COALESCE(cb.comment_count, 0) AS total_comments,
  COALESCE(lg.likes_given_count, 0) AS total_likes_given,
  COALESCE(lr.likes_received_count, 0) AS total_likes_received,
  COALESCE(fc.friend_count, 0) AS total_friends,
  (COALESCE(pb.post_count, 0) + COALESCE(cb.comment_count, 0) + COALESCE(lg.likes_given_count, 0) + COALESCE(lr.likes_received_count, 0) + COALESCE(fc.friend_count, 0)) AS total_engagement
FROM person p
LEFT JOIN posts_by_person pb ON pb.person_id = p.id
LEFT JOIN comments_by_person cb ON cb.person_id = p.id
LEFT JOIN likes_given_by_person lg ON lg.person_id = p.id
LEFT JOIN likes_received_by_person lr ON lr.person_id = p.id
LEFT JOIN friends_count_by_person fc ON fc.person_id = p.id
ORDER BY total_engagement DESC
LIMIT 10
