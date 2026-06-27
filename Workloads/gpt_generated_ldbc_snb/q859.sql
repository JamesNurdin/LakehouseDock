WITH
    friend_pairs AS (
        SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
    ),
    friend_counts AS (
        SELECT person_id, COUNT(DISTINCT friend_id) AS friend_count
        FROM friend_pairs
        GROUP BY person_id
    ),
    forum_counts AS (
        SELECT person_id, COUNT(DISTINCT forum_id) AS forum_count
        FROM forum_has_member_person
        GROUP BY person_id
    ),
    likes_counts AS (
        SELECT person_id, COUNT(*) AS likes_count
        FROM person_likes_post
        GROUP BY person_id
    ),
    work_counts AS (
        SELECT person_id, COUNT(DISTINCT company_id) AS company_count
        FROM person_work_at_company
        GROUP BY person_id
    ),
    study_counts AS (
        SELECT person_id, COUNT(DISTINCT university_id) AS university_count
        FROM person_study_at_university
        GROUP BY person_id
    ),
    person_first_company AS (
        SELECT sub.person_id, sub.company_name
        FROM (
            SELECT pwac.person_id,
                   org.name AS company_name,
                   pwac.work_from,
                   ROW_NUMBER() OVER (PARTITION BY pwac.person_id ORDER BY pwac.work_from) AS rn
            FROM person_work_at_company pwac
            JOIN organisation org ON org.id = pwac.company_id
        ) sub
        WHERE sub.rn = 1
    ),
    person_first_university AS (
        SELECT sub.person_id, sub.university_name, sub.class_year
        FROM (
            SELECT psau.person_id,
                   org.name AS university_name,
                   psau.class_year,
                   ROW_NUMBER() OVER (PARTITION BY psau.person_id ORDER BY psau.class_year DESC) AS rn
            FROM person_study_at_university psau
            JOIN organisation org ON org.id = psau.university_id
        ) sub
        WHERE sub.rn = 1
    )
SELECT
    p.id,
    p.first_name,
    p.last_name,
    COALESCE(fc.friend_count, 0) AS friend_count,
    COALESCE(fmc.forum_count, 0) AS forum_count,
    COALESCE(lc.likes_count, 0) AS likes_count,
    COALESCE(wc.company_count, 0) AS company_count,
    COALESCE(sc.university_count, 0) AS university_count,
    plc.name AS city_name,
    plc.type AS city_type,
    fco.company_name AS first_company,
    fu.university_name AS first_university,
    fu.class_year AS first_university_class_year
FROM person p
LEFT JOIN friend_counts fc ON fc.person_id = p.id
LEFT JOIN forum_counts fmc ON fmc.person_id = p.id
LEFT JOIN likes_counts lc ON lc.person_id = p.id
LEFT JOIN work_counts wc ON wc.person_id = p.id
LEFT JOIN study_counts sc ON sc.person_id = p.id
LEFT JOIN place plc ON plc.id = p.location_city_id
LEFT JOIN person_first_company fco ON fco.person_id = p.id
LEFT JOIN person_first_university fu ON fu.person_id = p.id
ORDER BY friend_count DESC
LIMIT 10
