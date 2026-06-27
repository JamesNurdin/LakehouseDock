WITH person_stats AS (
    SELECT
        p.id AS person_id,
        p.first_name,
        p.last_name,
        p.gender,
        pc.name AS city_name,
        COUNT(DISTINCT c.id) AS comment_count,
        COUNT(DISTINCT po.id) AS post_count,
        COUNT(DISTINCT iht.tag_id) AS interest_tag_count,
        COUNT(DISTINCT pw.company_id) AS work_company_count,
        COUNT(DISTINCT ps.university_id) AS study_university_count,
        COUNT(DISTINCT fm.forum_id) AS forum_membership_count,
        COUNT(DISTINCT plc.comment_id) AS likes_given_count,
        COUNT(DISTINCT plr.person_id) AS likes_received_count,
        COUNT(DISTINCT kp.friend_id) AS friend_count
    FROM person p
    LEFT JOIN place pc ON p.location_city_id = pc.id
    LEFT JOIN comment c ON c.creator_person_id = p.id
    LEFT JOIN post po ON po.creator_person_id = p.id
    LEFT JOIN person_has_interest_tag iht ON iht.person_id = p.id
    LEFT JOIN person_work_at_company pw ON pw.person_id = p.id
    LEFT JOIN person_study_at_university ps ON ps.person_id = p.id
    LEFT JOIN forum_has_member_person fm ON fm.person_id = p.id
    LEFT JOIN person_likes_comment plc ON plc.person_id = p.id
    LEFT JOIN person_likes_comment plr ON plr.comment_id = c.id
    LEFT JOIN (
        SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
    ) kp ON kp.person_id = p.id
    GROUP BY p.id, p.first_name, p.last_name, p.gender, pc.name
)
SELECT
    person_id,
    first_name,
    last_name,
    gender,
    city_name,
    comment_count,
    post_count,
    interest_tag_count,
    work_company_count,
    study_university_count,
    forum_membership_count,
    likes_given_count,
    likes_received_count,
    friend_count
FROM person_stats
ORDER BY comment_count DESC, post_count DESC
LIMIT 100
