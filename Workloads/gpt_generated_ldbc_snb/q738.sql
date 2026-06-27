WITH comment_counts AS (
    SELECT
        creator_person_id AS person_id,
        COUNT(*) AS total_comments_created
    FROM comment
    GROUP BY creator_person_id
),
comment_tag_counts AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(*) AS total_comment_tags
    FROM comment c
    JOIN comment_has_tag_tag ct ON ct.comment_id = c.id
    GROUP BY c.creator_person_id
),
comment_likes_given AS (
    SELECT
        person_id,
        COUNT(*) AS total_comment_likes_given
    FROM person_likes_comment
    GROUP BY person_id
),
post_counts AS (
    SELECT
        creator_person_id AS person_id,
        COUNT(*) AS total_posts_created
    FROM post
    GROUP BY creator_person_id
),
post_tag_counts AS (
    SELECT
        p.creator_person_id AS person_id,
        COUNT(*) AS total_post_tags
    FROM post p
    JOIN post_has_tag_tag pt ON pt.post_id = p.id
    GROUP BY p.creator_person_id
),
post_likes_given AS (
    SELECT
        person_id,
        COUNT(*) AS total_post_likes_given
    FROM person_likes_post
    GROUP BY person_id
),
person_company AS (
    SELECT
        pwac.person_id,
        o.name AS company_name,
        pwac.work_from
    FROM person_work_at_company pwac
    JOIN organisation o ON o.id = pwac.company_id
),
person_university AS (
    SELECT
        psu.person_id,
        o.name AS university_name,
        psu.class_year
    FROM person_study_at_university psu
    JOIN organisation o ON o.id = psu.university_id
),
person_location AS (
    SELECT
        p.id AS person_id,
        city.name AS city_name,
        country.name AS country_name
    FROM person p
    JOIN place city ON city.id = p.location_city_id
    LEFT JOIN place country ON country.id = city.part_of_place_id
)
SELECT
    p.id AS person_id,
    p.first_name,
    p.last_name,
    COALESCE(cc.total_comments_created, 0) AS total_comments_created,
    COALESCE(cl.total_comment_likes_given, 0) AS total_comment_likes_given,
    COALESCE(pl.total_post_likes_given, 0) AS total_post_likes_given,
    COALESCE(ctc.total_comment_tags, 0) AS total_comment_tags,
    COALESCE(ptc.total_post_tags, 0) AS total_post_tags,
    pc.company_name,
    pu.university_name,
    ploc.city_name,
    ploc.country_name
FROM person p
LEFT JOIN comment_counts cc ON cc.person_id = p.id
LEFT JOIN comment_likes_given cl ON cl.person_id = p.id
LEFT JOIN post_likes_given pl ON pl.person_id = p.id
LEFT JOIN comment_tag_counts ctc ON ctc.person_id = p.id
LEFT JOIN post_tag_counts ptc ON ptc.person_id = p.id
LEFT JOIN person_company pc ON pc.person_id = p.id
LEFT JOIN person_university pu ON pu.person_id = p.id
LEFT JOIN person_location ploc ON ploc.person_id = p.id
ORDER BY total_comments_created DESC, total_comment_likes_given DESC
LIMIT 100
