WITH liked_posts AS (
    SELECT plp.person_id,
           plp.post_id,
           p.length AS post_length
    FROM person_likes_post plp
    JOIN post p
      ON p.id = plp.post_id
),
post_tags AS (
    SELECT plp.person_id,
           pt.tag_id
    FROM person_likes_post plp
    JOIN post_has_tag_tag pt
      ON pt.post_id = plp.post_id
),
person_comments AS (
    SELECT c.creator_person_id AS person_id,
           COUNT(*) AS comment_count,
           AVG(c.length) AS avg_comment_length,
           COUNT(DISTINCT c.location_country_id) AS distinct_comment_countries
    FROM comment c
    GROUP BY c.creator_person_id
),
person_forums AS (
    SELECT f.moderator_person_id AS person_id,
           COUNT(*) AS moderated_forum_count
    FROM forum f
    GROUP BY f.moderator_person_id
),
person_universities AS (
    SELECT psu.person_id,
           COUNT(DISTINCT psu.university_id) AS university_count
    FROM person_study_at_university psu
    GROUP BY psu.person_id
)
SELECT p.id,
       p.first_name,
       p.last_name,
       COALESCE(lp.like_cnt, 0)                     AS liked_post_count,
       COALESCE(lp.avg_post_len, 0)                 AS avg_liked_post_length,
       COALESCE(pt.distinct_tag_cnt, 0)             AS distinct_tags_on_liked_posts,
       COALESCE(pc.comment_count, 0)                AS comment_count,
       COALESCE(pc.avg_comment_length, 0)           AS avg_comment_length,
       COALESCE(pc.distinct_comment_countries, 0)   AS distinct_comment_countries,
       COALESCE(pf.moderated_forum_count, 0)        AS moderated_forum_count,
       COALESCE(pu.university_count, 0)             AS university_count
FROM person p
LEFT JOIN (
    SELECT person_id,
           COUNT(*)               AS like_cnt,
           AVG(post_length)       AS avg_post_len
    FROM liked_posts
    GROUP BY person_id
) lp
  ON lp.person_id = p.id
LEFT JOIN (
    SELECT person_id,
           COUNT(DISTINCT tag_id) AS distinct_tag_cnt
    FROM post_tags
    GROUP BY person_id
) pt
  ON pt.person_id = p.id
LEFT JOIN person_comments pc
  ON pc.person_id = p.id
LEFT JOIN person_forums pf
  ON pf.person_id = p.id
LEFT JOIN person_universities pu
  ON pu.person_id = p.id
ORDER BY liked_post_count DESC, p.id
LIMIT 100
