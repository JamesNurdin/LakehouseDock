WITH person_base AS (
    SELECT id,
           first_name,
           last_name,
           gender,
           birthday,
           location_city_id
    FROM person
),
friend_counts AS (
    SELECT p.id AS person_id,
           COUNT(DISTINCT CASE 
               WHEN pk.person1_id = p.id THEN pk.person2_id
               ELSE pk.person1_id
           END) AS friend_count
    FROM person p
    LEFT JOIN person_knows_person pk
           ON pk.person1_id = p.id OR pk.person2_id = p.id
    GROUP BY p.id
),
post_stats AS (
    SELECT po.creator_person_id AS person_id,
           COUNT(*) AS post_count,
           AVG(po.length) AS avg_post_length,
           COUNT(DISTINCT po.container_forum_id) AS distinct_forum_count,
           COUNT(DISTINCT po.location_country_id) AS distinct_post_country_count
    FROM post po
    GROUP BY po.creator_person_id
),
post_likes_given AS (
    SELECT plp.person_id AS person_id,
           COUNT(*) AS post_likes_given
    FROM person_likes_post plp
    GROUP BY plp.person_id
),
post_likes_received AS (
    SELECT po.creator_person_id AS person_id,
           COUNT(*) AS post_likes_received
    FROM person_likes_post plp
    JOIN post po ON plp.post_id = po.id
    GROUP BY po.creator_person_id
),
post_tag_counts AS (
    SELECT po.creator_person_id AS person_id,
           COUNT(DISTINCT pht.tag_id) AS distinct_post_tag_count
    FROM post po
    JOIN post_has_tag_tag pht ON pht.post_id = po.id
    GROUP BY po.creator_person_id
),
comment_stats AS (
    SELECT c.creator_person_id AS person_id,
           COUNT(*) AS comment_count,
           AVG(c.length) AS avg_comment_length,
           COUNT(DISTINCT c.location_country_id) AS distinct_comment_country_count
    FROM comment c
    GROUP BY c.creator_person_id
),
comment_likes_given AS (
    SELECT clc.person_id AS person_id,
           COUNT(*) AS comment_likes_given
    FROM person_likes_comment clc
    GROUP BY clc.person_id
),
comment_likes_received AS (
    SELECT c.creator_person_id AS person_id,
           COUNT(*) AS comment_likes_received
    FROM person_likes_comment clc
    JOIN comment c ON clc.comment_id = c.id
    GROUP BY c.creator_person_id
),
comment_tag_counts AS (
    SELECT c.creator_person_id AS person_id,
           COUNT(DISTINCT cht.tag_id) AS distinct_comment_tag_count
    FROM comment c
    JOIN comment_has_tag_tag cht ON cht.comment_id = c.id
    GROUP BY c.creator_person_id
),
interest_counts AS (
    SELECT person_id,
           COUNT(DISTINCT tag_id) AS distinct_interest_tag_count
    FROM person_has_interest_tag
    GROUP BY person_id
)
SELECT pb.id,
       pb.first_name,
       pb.last_name,
       pb.gender,
       pb.birthday,
       COALESCE(fc.friend_count, 0)                         AS friend_count,
       COALESCE(ps.post_count, 0)                           AS post_count,
       COALESCE(ps.avg_post_length, 0)                      AS avg_post_length,
       COALESCE(plg.post_likes_given, 0)                    AS post_likes_given,
       COALESCE(plr.post_likes_received, 0)                AS post_likes_received,
       COALESCE(ptc.distinct_post_tag_count, 0)             AS distinct_post_tag_count,
       COALESCE(cs.comment_count, 0)                        AS comment_count,
       COALESCE(cs.avg_comment_length, 0)                   AS avg_comment_length,
       COALESCE(clg.comment_likes_given, 0)                 AS comment_likes_given,
       COALESCE(clr.comment_likes_received, 0)              AS comment_likes_received,
       COALESCE(ctc.distinct_comment_tag_count, 0)          AS distinct_comment_tag_count,
       COALESCE(ic.distinct_interest_tag_count, 0)          AS distinct_interest_tag_count,
       COALESCE(ps.distinct_forum_count, 0)                 AS distinct_forum_count,
       COALESCE(ps.distinct_post_country_count, 0)          AS distinct_post_country_count,
       COALESCE(cs.distinct_comment_country_count, 0)       AS distinct_comment_country_count
FROM person_base pb
LEFT JOIN friend_counts fc               ON fc.person_id = pb.id
LEFT JOIN post_stats ps                  ON ps.person_id = pb.id
LEFT JOIN post_likes_given plg           ON plg.person_id = pb.id
LEFT JOIN post_likes_received plr        ON plr.person_id = pb.id
LEFT JOIN post_tag_counts ptc            ON ptc.person_id = pb.id
LEFT JOIN comment_stats cs               ON cs.person_id = pb.id
LEFT JOIN comment_likes_given clg        ON clg.person_id = pb.id
LEFT JOIN comment_likes_received clr     ON clr.person_id = pb.id
LEFT JOIN comment_tag_counts ctc         ON ctc.person_id = pb.id
LEFT JOIN interest_counts ic             ON ic.person_id = pb.id
ORDER BY pb.id
