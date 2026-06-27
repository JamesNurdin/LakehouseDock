WITH base_person AS (
    SELECT p.id,
           p.first_name,
           p.last_name,
           p.gender,
           p.birthday,
           pl.name AS city_name
    FROM person p
    LEFT JOIN place pl ON p.location_city_id = pl.id
),
comment_stats AS (
    SELECT c.creator_person_id AS person_id,
           COUNT(*) AS total_comments_created,
           AVG(c.length) AS avg_comment_length
    FROM comment c
    GROUP BY c.creator_person_id
),
post_stats AS (
    SELECT po.creator_person_id AS person_id,
           COUNT(*) AS total_posts_created,
           AVG(po.length) AS avg_post_length
    FROM post po
    GROUP BY po.creator_person_id
),
comment_like_stats AS (
    SELECT plc.person_id,
           COUNT(DISTINCT plc.comment_id) AS total_comment_likes_given
    FROM person_likes_comment plc
    GROUP BY plc.person_id
),
post_like_stats AS (
    SELECT plp.person_id,
           COUNT(DISTINCT plp.post_id) AS total_post_likes_given
    FROM person_likes_post plp
    GROUP BY plp.person_id
),
friend_stats AS (
    SELECT pk.person1_id AS person_id,
           COUNT(DISTINCT pk.person2_id) AS total_friends_outgoing
    FROM person_knows_person pk
    GROUP BY pk.person1_id
),
interest_stats AS (
    SELECT pit.person_id,
           COUNT(DISTINCT pit.tag_id) AS total_interests
    FROM person_has_interest_tag pit
    GROUP BY pit.person_id
),
forum_stats AS (
    SELECT fm.person_id,
           COUNT(DISTINCT fm.forum_id) AS total_forums
    FROM forum_has_member_person fm
    GROUP BY fm.person_id
)
SELECT 
    bp.id,
    bp.first_name,
    bp.last_name,
    bp.gender,
    bp.birthday,
    bp.city_name,
    COALESCE(cs.total_comments_created, 0)            AS total_comments_created,
    COALESCE(cs.avg_comment_length, 0)                AS avg_comment_length,
    COALESCE(ps.total_posts_created, 0)               AS total_posts_created,
    COALESCE(ps.avg_post_length, 0)                   AS avg_post_length,
    COALESCE(cl.total_comment_likes_given, 0)        AS total_comment_likes_given,
    COALESCE(pl.total_post_likes_given, 0)           AS total_post_likes_given,
    COALESCE(fs.total_friends_outgoing, 0)           AS total_friends_outgoing,
    COALESCE(ints.total_interests, 0)                AS total_interests,
    COALESCE(fms.total_forums, 0)                    AS total_forums
FROM base_person bp
LEFT JOIN comment_stats cs      ON cs.person_id = bp.id
LEFT JOIN post_stats ps         ON ps.person_id = bp.id
LEFT JOIN comment_like_stats cl ON cl.person_id = bp.id
LEFT JOIN post_like_stats pl    ON pl.person_id = bp.id
LEFT JOIN friend_stats fs       ON fs.person_id = bp.id
LEFT JOIN interest_stats ints   ON ints.person_id = bp.id
LEFT JOIN forum_stats fms       ON fms.person_id = bp.id
ORDER BY total_friends_outgoing DESC, total_comments_created DESC
LIMIT 100
