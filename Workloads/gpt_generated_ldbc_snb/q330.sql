WITH
    friend_counts AS (
        SELECT person_id,
               COUNT(DISTINCT friend_id) AS friend_count
        FROM (
            SELECT person1_id AS person_id,
                   person2_id AS friend_id
            FROM   person_knows_person
            UNION ALL
            SELECT person2_id AS person_id,
                   person1_id AS friend_id
            FROM   person_knows_person
        )
        GROUP BY person_id
    ),
    post_stats AS (
        SELECT creator_person_id AS person_id,
               COUNT(*)            AS post_count,
               AVG(length)         AS avg_post_length
        FROM   post
        GROUP BY creator_person_id
    ),
    comment_stats AS (
        SELECT creator_person_id AS person_id,
               COUNT(*)            AS comment_count,
               AVG(length)         AS avg_comment_length
        FROM   comment
        GROUP BY creator_person_id
    ),
    likes_given_post AS (
        SELECT person_id,
               COUNT(*) AS likes_given_to_posts
        FROM   person_likes_post
        GROUP BY person_id
    ),
    likes_given_comment AS (
        SELECT person_id,
               COUNT(*) AS likes_given_to_comments
        FROM   person_likes_comment
        GROUP BY person_id
    ),
    likes_received_on_posts AS (
        SELECT p.creator_person_id AS person_id,
               COUNT(*)            AS likes_received_on_posts
        FROM   post p
        JOIN   person_likes_post plp ON p.id = plp.post_id
        GROUP BY p.creator_person_id
    ),
    likes_received_on_comments AS (
        SELECT c.creator_person_id AS person_id,
               COUNT(*)            AS likes_received_on_comments
        FROM   comment c
        JOIN   person_likes_comment plc ON c.id = plc.comment_id
        GROUP BY c.creator_person_id
    ),
    interest_counts AS (
        SELECT person_id,
               COUNT(*) AS interest_count
        FROM   person_has_interest_tag
        GROUP BY person_id
    ),
    person_city AS (
        SELECT p.id       AS person_id,
               pl.name    AS city_name
        FROM   person p
        LEFT JOIN place pl ON p.location_city_id = pl.id
    )
SELECT
    p.id,
    p.first_name,
    p.last_name,
    COALESCE(fc.friend_count, 0)                       AS friend_count,
    COALESCE(ps.post_count, 0)                        AS post_count,
    COALESCE(cs.comment_count, 0)                     AS comment_count,
    COALESCE(lgp.likes_given_to_posts, 0)             AS likes_given_to_posts,
    COALESCE(lgc.likes_given_to_comments, 0)          AS likes_given_to_comments,
    COALESCE(lrp.likes_received_on_posts, 0)          AS likes_received_on_posts,
    COALESCE(lrc.likes_received_on_comments, 0)      AS likes_received_on_comments,
    COALESCE(ic.interest_count, 0)                    AS interest_count,
    COALESCE(ps.avg_post_length, 0)                   AS avg_post_length,
    COALESCE(cs.avg_comment_length, 0)                AS avg_comment_length,
    pc.city_name,
    (COALESCE(fc.friend_count, 0) +
     COALESCE(ic.interest_count, 0) +
     COALESCE(lgp.likes_given_to_posts, 0) +
     COALESCE(lgc.likes_given_to_comments, 0) +
     COALESCE(lrp.likes_received_on_posts, 0) +
     COALESCE(lrc.likes_received_on_comments, 0))   AS total_engagement
FROM   person p
LEFT JOIN friend_counts fc               ON p.id = fc.person_id
LEFT JOIN post_stats ps                  ON p.id = ps.person_id
LEFT JOIN comment_stats cs               ON p.id = cs.person_id
LEFT JOIN likes_given_post lgp           ON p.id = lgp.person_id
LEFT JOIN likes_given_comment lgc        ON p.id = lgc.person_id
LEFT JOIN likes_received_on_posts lrp   ON p.id = lrp.person_id
LEFT JOIN likes_received_on_comments lrc ON p.id = lrc.person_id
LEFT JOIN interest_counts ic            ON p.id = ic.person_id
LEFT JOIN person_city pc                 ON p.id = pc.person_id
ORDER BY total_engagement DESC
LIMIT 10
