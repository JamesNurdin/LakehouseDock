WITH person_city AS (
  SELECT
    p.id AS person_id,
    p.location_city_id AS city_id,
    pl.name AS city_name
  FROM person p
  JOIN place pl ON p.location_city_id = pl.id
  WHERE pl.type = 'City'
),
comment_counts AS (
  SELECT
    c.creator_person_id AS person_id,
    COUNT(*) AS comment_count
  FROM comment c
  GROUP BY c.creator_person_id
),
likes_received AS (
  SELECT
    c.creator_person_id AS person_id,
    COUNT(plc.person_id) AS likes_received_count
  FROM comment c
  LEFT JOIN person_likes_comment plc ON c.id = plc.comment_id
  GROUP BY c.creator_person_id
),
likes_given AS (
  SELECT
    plc.person_id AS person_id,
    COUNT(*) AS likes_given_count
  FROM person_likes_comment plc
  GROUP BY plc.person_id
),
tag_counts AS (
  SELECT
    pit.person_id AS person_id,
    COUNT(DISTINCT pit.tag_id) AS distinct_tag_count
  FROM person_has_interest_tag pit
  GROUP BY pit.person_id
),
forum_moderators AS (
  SELECT
    f.moderator_person_id AS person_id,
    COUNT(*) AS moderated_forum_count
  FROM forum f
  GROUP BY f.moderator_person_id
)
SELECT
  pc.city_name,
  COUNT(DISTINCT pc.person_id) AS number_of_residents,
  COALESCE(SUM(cc.comment_count), 0) AS total_comments_by_residents,
  COALESCE(SUM(lr.likes_received_count), 0) AS total_likes_received_on_residents_comments,
  COALESCE(SUM(lg.likes_given_count), 0) AS total_likes_given_by_residents,
  COALESCE(SUM(tc.distinct_tag_count), 0) AS total_distinct_interest_tags_by_residents,
  COALESCE(SUM(fm.moderated_forum_count), 0) AS total_forums_moderated_by_residents,
  CASE WHEN COUNT(DISTINCT pc.person_id) = 0 THEN 0
       ELSE COALESCE(SUM(cc.comment_count), 0) * 1.0 / COUNT(DISTINCT pc.person_id) END AS avg_comments_per_resident,
  CASE WHEN COUNT(DISTINCT pc.person_id) = 0 THEN 0
       ELSE COALESCE(SUM(lr.likes_received_count), 0) * 1.0 / COUNT(DISTINCT pc.person_id) END AS avg_likes_received_per_resident
FROM person_city pc
LEFT JOIN comment_counts cc ON pc.person_id = cc.person_id
LEFT JOIN likes_received lr ON pc.person_id = lr.person_id
LEFT JOIN likes_given lg ON pc.person_id = lg.person_id
LEFT JOIN tag_counts tc ON pc.person_id = tc.person_id
LEFT JOIN forum_moderators fm ON pc.person_id = fm.person_id
GROUP BY pc.city_name
ORDER BY total_comments_by_residents DESC
LIMIT 20
