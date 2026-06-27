WITH friend_counts AS (
  SELECT person1_id AS person_id,
         COUNT(*) AS friend_count
  FROM person_knows_person
  GROUP BY person1_id
),
created_posts AS (
  SELECT creator_person_id AS person_id,
         COUNT(*) AS created_post_count,
         AVG(length) AS avg_created_post_length
  FROM post
  GROUP BY creator_person_id
),
liked_posts AS (
  SELECT plp.person_id,
         COUNT(*) AS liked_post_count,
         AVG(p.length) AS avg_liked_post_length
  FROM person_likes_post plp
  JOIN post p ON plp.post_id = p.id
  GROUP BY plp.person_id
),
interest_counts AS (
  SELECT person_id,
         COUNT(DISTINCT tag_id) AS interest_tag_count
  FROM person_has_interest_tag
  GROUP BY person_id
)
SELECT p.id,
       p.first_name,
       p.last_name,
       COALESCE(fc.friend_count, 0) AS friend_count,
       COALESCE(cp.created_post_count, 0) AS created_post_count,
       COALESCE(cp.avg_created_post_length, 0) AS avg_created_post_length,
       COALESCE(lp.liked_post_count, 0) AS liked_post_count,
       COALESCE(lp.avg_liked_post_length, 0) AS avg_liked_post_length,
       COALESCE(ic.interest_tag_count, 0) AS interest_tag_count
FROM person p
LEFT JOIN friend_counts fc ON p.id = fc.person_id
LEFT JOIN created_posts cp ON p.id = cp.person_id
LEFT JOIN liked_posts lp ON p.id = lp.person_id
LEFT JOIN interest_counts ic ON p.id = ic.person_id
ORDER BY friend_count DESC, created_post_count DESC
LIMIT 100
