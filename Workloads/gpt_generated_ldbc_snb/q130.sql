WITH
person_info AS (
    SELECT
        p.id AS person_id,
        p.first_name,
        p.last_name,
        pl.name AS city_name
    FROM person p
    LEFT JOIN place pl
        ON p.location_city_id = pl.id
),
comments_agg AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(*) AS total_comments_created,
        SUM(c.length) AS total_comment_length,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    GROUP BY c.creator_person_id
),
likes_given_agg AS (
    SELECT
        plc.person_id AS person_id,
        COUNT(*) AS total_likes_given
    FROM person_likes_comment plc
    GROUP BY plc.person_id
),
likes_received_agg AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(plc.comment_id) AS total_likes_received
    FROM comment c
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY c.creator_person_id
),
tags_agg AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(DISTINCT cht.tag_id) AS total_tags_on_comments
    FROM comment c
    JOIN comment_has_tag_tag cht
        ON cht.comment_id = c.id
    GROUP BY c.creator_person_id
),
posts_agg AS (
    SELECT
        p.creator_person_id AS person_id,
        COUNT(*) AS total_posts_created
    FROM post p
    GROUP BY p.creator_person_id
),
universities_agg AS (
    SELECT
        psu.person_id AS person_id,
        COUNT(DISTINCT org.id) AS total_universities_attended
    FROM person_study_at_university psu
    JOIN organisation org
        ON psu.university_id = org.id
    GROUP BY psu.person_id
)

SELECT
    pi.person_id,
    pi.first_name,
    pi.last_name,
    pi.city_name,
    COALESCE(ca.total_comments_created, 0) AS total_comments_created,
    COALESCE(ca.total_comment_length, 0) AS total_comment_length,
    COALESCE(ca.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(lg.total_likes_given, 0) AS total_likes_given,
    COALESCE(lr.total_likes_received, 0) AS total_likes_received,
    COALESCE(ta.total_tags_on_comments, 0) AS total_tags_on_comments,
    COALESCE(pa.total_posts_created, 0) AS total_posts_created,
    COALESCE(ua.total_universities_attended, 0) AS total_universities_attended
FROM person_info pi
LEFT JOIN comments_agg ca ON pi.person_id = ca.person_id
LEFT JOIN likes_given_agg lg ON pi.person_id = lg.person_id
LEFT JOIN likes_received_agg lr ON pi.person_id = lr.person_id
LEFT JOIN tags_agg ta ON pi.person_id = ta.person_id
LEFT JOIN posts_agg pa ON pi.person_id = pa.person_id
LEFT JOIN universities_agg ua ON pi.person_id = ua.person_id
ORDER BY total_comments_created DESC
LIMIT 100
