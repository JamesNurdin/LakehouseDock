/*
  Analytical query for the LDBC SNB BI dataset (sf0003).
  For each person we compute:
    • Number of posts they created
    • Number of comments they created
    • Number of posts they liked
    • Average length of the posts they liked
    • Distinct number of tags on posts they liked
    • Distinct number of countries (places) where they have commented
  The query uses only the six selected tables and follows the allowed join rules.
*/
WITH person_base AS (
    SELECT id, first_name, last_name
    FROM person
),
posts_created AS (
    SELECT creator_person_id AS person_id,
           COUNT(*) AS posts_created
    FROM post
    GROUP BY creator_person_id
),
comments_created AS (
    SELECT creator_person_id AS person_id,
           COUNT(*) AS comments_created
    FROM comment
    GROUP BY creator_person_id
),
likes_agg AS (
    SELECT plp.person_id AS person_id,
           COUNT(*) AS liked_posts,
           AVG(p.length) AS avg_liked_post_length,
           COUNT(DISTINCT pht.tag_id) AS distinct_tags_on_liked_posts
    FROM person_likes_post plp
    LEFT JOIN post p ON p.id = plp.post_id               -- allowed: person_likes_post.post_id = post.id
    LEFT JOIN post_has_tag_tag pht ON pht.post_id = p.id -- allowed: post_has_tag_tag.post_id = post.id
    GROUP BY plp.person_id
),
comment_countries AS (
    SELECT c.creator_person_id AS person_id,
           COUNT(DISTINCT pl.id) AS distinct_comment_countries
    FROM comment c
    LEFT JOIN place pl ON pl.id = c.location_country_id   -- allowed: comment.location_country_id = place.id
    GROUP BY c.creator_person_id
)
SELECT
    pb.id AS person_id,
    pb.first_name,
    pb.last_name,
    COALESCE(pc.posts_created, 0)               AS posts_created,
    COALESCE(cc.comments_created, 0)            AS comments_created,
    COALESCE(la.liked_posts, 0)                 AS liked_posts,
    la.avg_liked_post_length,
    COALESCE(la.distinct_tags_on_liked_posts, 0) AS distinct_tags_on_liked_posts,
    COALESCE(ccn.distinct_comment_countries, 0) AS distinct_comment_countries
FROM person_base pb
LEFT JOIN posts_created pc   ON pc.person_id = pb.id
LEFT JOIN comments_created cc ON cc.person_id = pb.id
LEFT JOIN likes_agg la        ON la.person_id = pb.id
LEFT JOIN comment_countries ccn ON ccn.person_id = pb.id
ORDER BY posts_created DESC, liked_posts DESC
LIMIT 20
