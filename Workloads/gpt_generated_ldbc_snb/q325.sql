WITH post_counts AS (
    SELECT creator_person_id AS person_id,
           COUNT(*)               AS post_cnt
    FROM post
    GROUP BY creator_person_id
),
comment_counts AS (
    SELECT creator_person_id AS person_id,
           COUNT(*)               AS comment_cnt
    FROM comment
    GROUP BY creator_person_id
),
post_like_counts AS (
    SELECT person_id,
           COUNT(*) AS post_like_cnt
    FROM person_likes_post
    GROUP BY person_id
),
comment_like_counts AS (
    SELECT person_id,
           COUNT(*) AS comment_like_cnt
    FROM person_likes_comment
    GROUP BY person_id
),
connection_counts AS (
    SELECT person_id,
           COUNT(DISTINCT friend_id) AS connection_cnt
    FROM (
        SELECT person1_id AS person_id,
               person2_id AS friend_id
        FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id,
               person1_id AS friend_id
        FROM person_knows_person
    ) AS c
    GROUP BY person_id
),
interest_counts AS (
    SELECT person_id,
           COUNT(DISTINCT tag_id) AS interest_cnt
    FROM person_has_interest_tag
    GROUP BY person_id
),
person_city AS (
    SELECT p.id        AS person_id,
           p.first_name,
           p.last_name,
           p.gender,
           p.birthday,
           pl.name      AS city_name
    FROM person p
    LEFT JOIN place pl
        ON p.location_city_id = pl.id
)
SELECT
    pc.person_id,
    pc.first_name,
    pc.last_name,
    pc.gender,
    pc.birthday,
    pc.city_name,
    COALESCE(pcnt.post_cnt, 0)          AS posts_created,
    COALESCE(ccnt.comment_cnt, 0)       AS comments_created,
    COALESCE(plcnt.post_like_cnt, 0)    AS post_likes_given,
    COALESCE(clcnt.comment_like_cnt, 0) AS comment_likes_given,
    COALESCE(conncnt.connection_cnt, 0) AS connections,
    COALESCE(intcnt.interest_cnt, 0)    AS distinct_interests,
    (COALESCE(pcnt.post_cnt, 0)
     + COALESCE(ccnt.comment_cnt, 0)
     + COALESCE(plcnt.post_like_cnt, 0)
     + COALESCE(clcnt.comment_like_cnt, 0)
     + COALESCE(conncnt.connection_cnt, 0)) AS engagement_score
FROM person_city pc
LEFT JOIN post_counts pcnt
    ON pc.person_id = pcnt.person_id
LEFT JOIN comment_counts ccnt
    ON pc.person_id = ccnt.person_id
LEFT JOIN post_like_counts plcnt
    ON pc.person_id = plcnt.person_id
LEFT JOIN comment_like_counts clcnt
    ON pc.person_id = clcnt.person_id
LEFT JOIN connection_counts conncnt
    ON pc.person_id = conncnt.person_id
LEFT JOIN interest_counts intcnt
    ON pc.person_id = intcnt.person_id
ORDER BY engagement_score DESC
LIMIT 10
