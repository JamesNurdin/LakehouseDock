WITH person_activity AS (
    SELECT
        p.id AS person_id,
        p.first_name,
        p.last_name,
        pl_city.name AS city_name,
        COUNT(DISTINCT kp.person2_id) AS friend_count,
        COUNT(DISTINCT plp.post_id) AS liked_posts,
        COUNT(DISTINCT plc.comment_id) AS liked_comments,
        COUNT(DISTINCT po.id) AS post_count,
        COUNT(DISTINCT fm.forum_id) AS forum_membership_count,
        COUNT(DISTINCT pit.tag_id) AS interest_tag_count,
        COUNT(DISTINCT pw.company_id) AS company_count,
        COUNT(DISTINCT ps.university_id) AS university_count
    FROM person p
    LEFT JOIN place pl_city
        ON pl_city.id = p.location_city_id
    LEFT JOIN person_knows_person kp
        ON kp.person1_id = p.id
    LEFT JOIN person_likes_post plp
        ON plp.person_id = p.id
    LEFT JOIN person_likes_comment plc
        ON plc.person_id = p.id
    LEFT JOIN post po
        ON po.creator_person_id = p.id
    LEFT JOIN forum_has_member_person fm
        ON fm.person_id = p.id
    LEFT JOIN person_has_interest_tag pit
        ON pit.person_id = p.id
    LEFT JOIN person_work_at_company pw
        ON pw.person_id = p.id
    LEFT JOIN person_study_at_university ps
        ON ps.person_id = p.id
    GROUP BY p.id, p.first_name, p.last_name, pl_city.name
)
SELECT
    person_id,
    first_name,
    last_name,
    city_name,
    friend_count,
    liked_posts,
    liked_comments,
    post_count,
    forum_membership_count,
    interest_tag_count,
    company_count,
    university_count,
    (friend_count + liked_posts + liked_comments + post_count + forum_membership_count) AS activity_score
FROM person_activity
ORDER BY activity_score DESC
LIMIT 10
