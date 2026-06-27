WITH
    friend_counts AS (
        SELECT
            person_id,
            COUNT(DISTINCT friend_id) AS friend_count
        FROM (
            SELECT person1_id AS person_id, person2_id AS friend_id
            FROM person_knows_person
            UNION ALL
            SELECT person2_id AS person_id, person1_id AS friend_id
            FROM person_knows_person
        )
        GROUP BY person_id
    ),
    forum_counts AS (
        SELECT
            person_id,
            COUNT(DISTINCT forum_id) AS forum_count
        FROM forum_has_member_person
        GROUP BY person_id
    ),
    interest_counts AS (
        SELECT
            person_id,
            COUNT(DISTINCT tag_id) AS interest_count
        FROM person_has_interest_tag
        GROUP BY person_id
    ),
    post_created_counts AS (
        SELECT
            creator_person_id AS person_id,
            COUNT(DISTINCT id) AS post_created_count,
            AVG(length) AS avg_post_length
        FROM post
        GROUP BY creator_person_id
    ),
    post_liked_counts AS (
        SELECT
            pl.person_id,
            COUNT(DISTINCT pl.post_id) AS post_liked_count,
            SUM(p.length) AS total_liked_post_length
        FROM person_likes_post pl
        JOIN post p ON pl.post_id = p.id
        GROUP BY pl.person_id
    ),
    comment_liked_counts AS (
        SELECT
            person_id,
            COUNT(DISTINCT comment_id) AS comment_liked_count
        FROM person_likes_comment
        GROUP BY person_id
    ),
    company_counts AS (
        SELECT
            person_id,
            COUNT(DISTINCT company_id) AS company_count
        FROM person_work_at_company
        GROUP BY person_id
    ),
    university_counts AS (
        SELECT
            person_id,
            COUNT(DISTINCT university_id) AS university_count
        FROM person_study_at_university
        GROUP BY person_id
    ),
    city_names AS (
        SELECT
            p.id AS person_id,
            pl.name AS city_name
        FROM person p
        LEFT JOIN place pl ON p.location_city_id = pl.id
    )
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    p.email,
    cn.city_name,
    COALESCE(fc.friend_count, 0) AS friend_count,
    COALESCE(fr.forum_count, 0) AS forum_membership_count,
    COALESCE(ic.interest_count, 0) AS interest_tag_count,
    COALESCE(pc.post_created_count, 0) AS post_created_count,
    COALESCE(pc.avg_post_length, 0) AS avg_created_post_length,
    COALESCE(plc.post_liked_count, 0) AS post_liked_count,
    COALESCE(plc.total_liked_post_length, 0) AS total_liked_post_length,
    COALESCE(clc.comment_liked_count, 0) AS comment_liked_count,
    COALESCE(cc.company_count, 0) AS company_count,
    COALESCE(uc.university_count, 0) AS university_count,
    (
        COALESCE(fc.friend_count, 0) +
        COALESCE(fr.forum_count, 0) +
        COALESCE(ic.interest_count, 0) +
        COALESCE(pc.post_created_count, 0) +
        COALESCE(plc.post_liked_count, 0) +
        COALESCE(clc.comment_liked_count, 0) +
        COALESCE(cc.company_count, 0) +
        COALESCE(uc.university_count, 0)
    ) AS total_activity
FROM person p
LEFT JOIN city_names cn ON p.id = cn.person_id
LEFT JOIN friend_counts fc ON p.id = fc.person_id
LEFT JOIN forum_counts fr ON p.id = fr.person_id
LEFT JOIN interest_counts ic ON p.id = ic.person_id
LEFT JOIN post_created_counts pc ON p.id = pc.person_id
LEFT JOIN post_liked_counts plc ON p.id = plc.person_id
LEFT JOIN comment_liked_counts clc ON p.id = clc.person_id
LEFT JOIN company_counts cc ON p.id = cc.person_id
LEFT JOIN university_counts uc ON p.id = uc.person_id
ORDER BY total_activity DESC
LIMIT 100
