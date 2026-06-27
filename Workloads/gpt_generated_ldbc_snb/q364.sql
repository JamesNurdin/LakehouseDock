WITH
members AS (
    SELECT fhm.forum_id,
           fhm.person_id AS member_id
    FROM forum_has_member_person fhm
    JOIN person p
      ON fhm.person_id = p.id
),
comment_stats AS (
    SELECT m.forum_id,
           c.id AS comment_id,
           c.length
    FROM members m
    JOIN comment c
      ON c.creator_person_id = m.member_id
),
comment_likes AS (
    SELECT cs.forum_id,
           COUNT(plc.person_id) AS like_count
    FROM comment_stats cs
    JOIN person_likes_comment plc
      ON plc.comment_id = cs.comment_id
    GROUP BY cs.forum_id
),
member_counts AS (
    SELECT forum_id,
           COUNT(DISTINCT member_id) AS member_count
    FROM members
    GROUP BY forum_id
),
comment_aggregates AS (
    SELECT forum_id,
           COUNT(DISTINCT comment_id) AS comment_count,
           SUM(length) AS total_comment_length,
           AVG(length) AS avg_comment_length
    FROM comment_stats
    GROUP BY forum_id
),
member_tags AS (
    SELECT m.forum_id,
           pht.tag_id
    FROM members m
    JOIN person_has_interest_tag pht
      ON pht.person_id = m.member_id
),
tag_counts AS (
    SELECT forum_id,
           COUNT(DISTINCT tag_id) AS distinct_tag_count
    FROM member_tags
    GROUP BY forum_id
),
moderators AS (
    SELECT f.id AS forum_id,
           p.first_name,
           p.last_name
    FROM forum f
    JOIN person p
      ON f.moderator_person_id = p.id
)
SELECT f.id AS forum_id,
       f.title,
       modr.first_name AS moderator_first_name,
       modr.last_name AS moderator_last_name,
       mc.member_count,
       ca.comment_count,
       ca.total_comment_length,
       ca.avg_comment_length,
       COALESCE(cl.like_count, 0) AS total_likes_on_member_comments,
       tc.distinct_tag_count
FROM forum f
LEFT JOIN moderators modr
  ON modr.forum_id = f.id
LEFT JOIN member_counts mc
  ON mc.forum_id = f.id
LEFT JOIN comment_aggregates ca
  ON ca.forum_id = f.id
LEFT JOIN comment_likes cl
  ON cl.forum_id = f.id
LEFT JOIN tag_counts tc
  ON tc.forum_id = f.id
ORDER BY total_likes_on_member_comments DESC
LIMIT 10
