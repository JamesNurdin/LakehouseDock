WITH comment_stats AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(*) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    GROUP BY c.creator_person_id
),
likes_received AS (
    SELECT
        c.creator_person_id AS person_id,
        COUNT(plc.person_id) AS likes_received
    FROM comment c
    LEFT JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    GROUP BY c.creator_person_id
),
friend_counts AS (
    SELECT
        kp.person1_id AS person_id,
        COUNT(DISTINCT kp.person2_id) AS friends_count
    FROM person_knows_person kp
    GROUP BY kp.person1_id
),
work_counts AS (
    SELECT
        pwc.person_id,
        COUNT(DISTINCT pwc.company_id) AS companies_count
    FROM person_work_at_company pwc
    GROUP BY pwc.person_id
),
study_counts AS (
    SELECT
        psu.person_id,
        COUNT(DISTINCT psu.university_id) AS universities_count
    FROM person_study_at_university psu
    GROUP BY psu.person_id
),
post_likes AS (
    SELECT
        plp.person_id,
        COUNT(DISTINCT plp.post_id) AS posts_liked
    FROM person_likes_post plp
    GROUP BY plp.person_id
),
comment_likes AS (
    SELECT
        plc.person_id,
        COUNT(DISTINCT plc.comment_id) AS comments_liked
    FROM person_likes_comment plc
    GROUP BY plc.person_id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    pl_city.name AS city_name,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(lr.likes_received, 0) AS likes_received,
    COALESCE(fc.friends_count, 0) AS friends_count,
    COALESCE(wc.companies_count, 0) AS companies_count,
    COALESCE(sc.universities_count, 0) AS universities_count,
    COALESCE(pl.posts_liked, 0) AS posts_liked,
    COALESCE(cl.comments_liked, 0) AS comments_liked
FROM person p
LEFT JOIN place pl_city
    ON p.location_city_id = pl_city.id
LEFT JOIN comment_stats cs
    ON cs.person_id = p.id
LEFT JOIN likes_received lr
    ON lr.person_id = p.id
LEFT JOIN friend_counts fc
    ON fc.person_id = p.id
LEFT JOIN work_counts wc
    ON wc.person_id = p.id
LEFT JOIN study_counts sc
    ON sc.person_id = p.id
LEFT JOIN post_likes pl
    ON pl.person_id = p.id
LEFT JOIN comment_likes cl
    ON cl.person_id = p.id
ORDER BY likes_received DESC, comment_count DESC
LIMIT 100
