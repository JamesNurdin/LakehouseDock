WITH
  friends AS (
    SELECT person1_id AS person_id, person2_id AS friend_id
    FROM person_knows_person
    UNION ALL
    SELECT person2_id AS person_id, person1_id AS friend_id
    FROM person_knows_person
  ),
  friend_counts AS (
    SELECT person_id,
           COUNT(DISTINCT friend_id) AS num_friends
    FROM friends
    GROUP BY person_id
  ),
  post_metrics AS (
    SELECT creator_person_id AS person_id,
           COUNT(*) AS num_posts,
           SUM(length) AS total_post_length
    FROM post
    GROUP BY creator_person_id
  ),
  comment_metrics AS (
    SELECT creator_person_id AS person_id,
           COUNT(*) AS num_comments,
           SUM(length) AS total_comment_length
    FROM comment
    GROUP BY creator_person_id
  ),
  post_likes AS (
    SELECT person_id,
           COUNT(DISTINCT post_id) AS num_posts_liked
    FROM person_likes_post
    GROUP BY person_id
  ),
  comment_likes AS (
    SELECT person_id,
           COUNT(DISTINCT comment_id) AS num_comments_liked
    FROM person_likes_comment
    GROUP BY person_id
  ),
  person_details AS (
    SELECT id,
           first_name,
           last_name,
           gender,
           birthday,
           location_city_id,
           language,
           email
    FROM person
  )
SELECT
  pd.id,
  pd.first_name,
  pd.last_name,
  COALESCE(fc.num_friends, 0)        AS num_friends,
  COALESCE(pm.num_posts, 0)          AS num_posts_authored,
  COALESCE(pm.total_post_length, 0)  AS total_post_length,
  COALESCE(cm.num_comments, 0)       AS num_comments_authored,
  COALESCE(cm.total_comment_length, 0) AS total_comment_length,
  COALESCE(pl.num_posts_liked, 0)    AS num_posts_liked,
  COALESCE(cl.num_comments_liked, 0) AS num_comments_liked
FROM person_details pd
LEFT JOIN friend_counts fc   ON fc.person_id = pd.id
LEFT JOIN post_metrics pm    ON pm.person_id = pd.id
LEFT JOIN comment_metrics cm ON cm.person_id = pd.id
LEFT JOIN post_likes pl      ON pl.person_id = pd.id
LEFT JOIN comment_likes cl   ON cl.person_id = pd.id
ORDER BY pd.id
