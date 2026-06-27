WITH forum_members AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date AS forum_creation_date,
        f.moderator_person_id,
        m.person_id AS member_id
    FROM forum f
    JOIN forum_has_member_person m
        ON m.forum_id = f.id
),
member_friends AS (
    SELECT
        pk.person1_id AS person_id,
        COUNT(DISTINCT pk.person2_id) AS friend_count
    FROM person_knows_person pk
    GROUP BY pk.person1_id
)
SELECT
    fm.forum_id,
    fm.title,
    fm.forum_creation_date,
    mod.first_name || ' ' || mod.last_name AS moderator_name,
    pcity.name AS moderator_city,
    COUNT(DISTINCT fm.member_id) AS member_count,
    COUNT(DISTINCT it.tag_id) AS distinct_interest_tags,
    ROUND(AVG(DATE_DIFF('year', DATE_PARSE(p.birthday, '%Y-%m-%d'), CURRENT_DATE)), 1) AS avg_member_age,
    AVG(mf.friend_count) AS avg_friends_per_member,
    COUNT(DISTINCT su.university_id) AS distinct_universities_of_members
FROM forum_members fm
JOIN person mod
    ON mod.id = fm.moderator_person_id
LEFT JOIN place pcity
    ON pcity.id = mod.location_city_id
JOIN person p
    ON p.id = fm.member_id
LEFT JOIN person_has_interest_tag it
    ON it.person_id = fm.member_id
LEFT JOIN member_friends mf
    ON mf.person_id = fm.member_id
LEFT JOIN person_study_at_university su
    ON su.person_id = fm.member_id
GROUP BY
    fm.forum_id,
    fm.title,
    fm.forum_creation_date,
    mod.first_name,
    mod.last_name,
    pcity.name
ORDER BY member_count DESC
LIMIT 10
