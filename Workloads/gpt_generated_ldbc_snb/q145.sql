WITH forum_posts AS (
  SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    f.creation_date AS forum_creation_date,
    mod.id AS moderator_id,
    mod.first_name AS moderator_first_name,
    mod.last_name AS moderator_last_name,
    p.id AS post_id,
    p.length AS post_length,
    p.creator_person_id AS creator_id,
    p.location_country_id AS post_country_id,
    pc.name AS post_country_name
  FROM forum f
  JOIN person mod ON f.moderator_person_id = mod.id
  JOIN post p ON p.container_forum_id = f.id
  LEFT JOIN place pc ON p.location_country_id = pc.id
),
post_likes AS (
  SELECT
    fp.forum_id,
    fp.post_id,
    COUNT(plp.person_id) AS like_count
  FROM forum_posts fp
  JOIN person_likes_post plp ON plp.post_id = fp.post_id
  GROUP BY fp.forum_id, fp.post_id
),
creator_set AS (
  SELECT DISTINCT forum_id, creator_id
  FROM forum_posts
),
creator_friend_counts AS (
  SELECT
    cs.forum_id,
    cs.creator_id,
    COUNT(DISTINCT pkp.person2_id) AS friend_creator_count
  FROM creator_set cs
  JOIN person_knows_person pkp ON pkp.person1_id = cs.creator_id
  JOIN creator_set cs2 ON cs2.forum_id = cs.forum_id AND cs2.creator_id = pkp.person2_id
  GROUP BY cs.forum_id, cs.creator_id
),
avg_friend_counts AS (
  SELECT
    forum_id,
    AVG(friend_creator_count) AS avg_friend_connections
  FROM creator_friend_counts
  GROUP BY forum_id
)
SELECT
  fp.forum_id,
  fp.forum_title,
  fp.forum_creation_date,
  fp.moderator_first_name || ' ' || fp.moderator_last_name AS moderator_name,
  COUNT(DISTINCT fp.post_id) AS total_posts,
  SUM(fp.post_length) AS total_post_length,
  AVG(fp.post_length) AS avg_post_length,
  COUNT(DISTINCT fp.creator_id) AS distinct_creators,
  COALESCE(SUM(pl.like_count), 0) AS total_likes_on_posts,
  COUNT(DISTINCT fp.post_country_name) AS distinct_countries_of_posts,
  COALESCE(afc.avg_friend_connections, 0) AS avg_friend_connections_per_creator
FROM forum_posts fp
LEFT JOIN post_likes pl ON pl.forum_id = fp.forum_id
LEFT JOIN avg_friend_counts afc ON afc.forum_id = fp.forum_id
GROUP BY
  fp.forum_id,
  fp.forum_title,
  fp.forum_creation_date,
  fp.moderator_first_name,
  fp.moderator_last_name,
  COALESCE(afc.avg_friend_connections, 0)
ORDER BY total_posts DESC
LIMIT 10
