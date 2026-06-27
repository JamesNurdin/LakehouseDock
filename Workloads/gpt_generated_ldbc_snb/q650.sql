WITH comment_counts AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(DISTINCT c.id) AS comment_created_cnt,
        COUNT(plc.person_id) AS comment_liked_cnt
    FROM comment c
    LEFT JOIN person_likes_comment plc ON plc.comment_id = c.id
    GROUP BY c.creator_person_id
),
post_counts AS (
    SELECT
        p.creator_person_id AS person_id,
        COUNT(DISTINCT p.id) AS post_created_cnt,
        COUNT(plp.person_id) AS post_liked_cnt
    FROM post p
    LEFT JOIN person_likes_post plp ON plp.post_id = p.id
    GROUP BY p.creator_person_id
),
friend_counts AS (
    SELECT
        kp.person1_id AS person_id,
        COUNT(DISTINCT kp.person2_id) AS friends_cnt
    FROM person_knows_person kp
    GROUP BY kp.person1_id
),
forum_counts AS (
    SELECT
        fmp.person_id AS person_id,
        COUNT(DISTINCT fmp.forum_id) AS forums_cnt
    FROM forum_has_member_person fmp
    GROUP BY fmp.person_id
)
SELECT
    per.id,
    per.first_name,
    per.last_name,
    per.gender,
    per.birthday,
    COALESCE(cc.comment_created_cnt, 0) AS comment_created_cnt,
    COALESCE(cc.comment_liked_cnt, 0) AS comment_liked_cnt,
    COALESCE(pc.post_created_cnt, 0) AS post_created_cnt,
    COALESCE(pc.post_liked_cnt, 0) AS post_liked_cnt,
    COALESCE(fr.friends_cnt, 0) AS friends_cnt,
    COALESCE(fc.forums_cnt, 0) AS forums_cnt,
    pl.name AS city_name
FROM person per
LEFT JOIN comment_counts cc ON cc.person_id = per.id
LEFT JOIN post_counts pc ON pc.person_id = per.id
LEFT JOIN friend_counts fr ON fr.person_id = per.id
LEFT JOIN forum_counts fc ON fc.person_id = per.id
LEFT JOIN place pl ON per.location_city_id = pl.id
ORDER BY per.id
