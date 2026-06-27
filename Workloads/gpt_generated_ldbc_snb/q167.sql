WITH forum_mod AS (
    SELECT
        f.id AS forum_id,
        f.title,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name,
        mod.location_city_id AS moderator_city_id
    FROM forum f
    JOIN person mod ON mod.id = f.moderator_person_id
),
members AS (
    SELECT
        fm.forum_id,
        m.person_id
    FROM forum_has_member_person m
    JOIN forum_mod fm ON fm.forum_id = m.forum_id
),
total_members AS (
    SELECT
        forum_id,
        COUNT(DISTINCT person_id) AS total_members
    FROM members
    GROUP BY forum_id
),
member_interests AS (
    SELECT
        m.forum_id,
        it.tag_id
    FROM members m
    JOIN person_has_interest_tag it ON it.person_id = m.person_id
),
distinct_interests AS (
    SELECT
        forum_id,
        COUNT(DISTINCT tag_id) AS distinct_interests
    FROM member_interests
    GROUP BY forum_id
),
friend_counts AS (
    SELECT
        person_id,
        COUNT(DISTINCT friend_id) AS friend_count
    FROM (
        SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
    ) pk
    GROUP BY person_id
),
member_friends AS (
    SELECT
        m.forum_id,
        COALESCE(fc.friend_count, 0) AS friend_count
    FROM members m
    LEFT JOIN friend_counts fc ON fc.person_id = m.person_id
),
avg_friends AS (
    SELECT
        forum_id,
        AVG(friend_count) AS avg_friends
    FROM member_friends
    GROUP BY forum_id
),
member_work_flag AS (
    SELECT
        m.forum_id,
        CASE
            WHEN comp_city.id = fm.moderator_city_id THEN 1
            ELSE 0
        END AS works_in_mod_city
    FROM members m
    LEFT JOIN person_work_at_company pwc ON pwc.person_id = m.person_id
    LEFT JOIN organisation org ON org.id = pwc.company_id
    LEFT JOIN place comp_city ON comp_city.id = org.location_place_id
    JOIN forum_mod fm ON fm.forum_id = m.forum_id
),
members_working_in_mod_city AS (
    SELECT
        forum_id,
        SUM(works_in_mod_city) AS members_working_in_mod_city
    FROM member_work_flag
    GROUP BY forum_id
)
SELECT
    fm.forum_id,
    fm.title,
    fm.moderator_first_name,
    fm.moderator_last_name,
    tm.total_members,
    di.distinct_interests,
    af.avg_friends,
    mwc.members_working_in_mod_city
FROM forum_mod fm
LEFT JOIN total_members tm ON tm.forum_id = fm.forum_id
LEFT JOIN distinct_interests di ON di.forum_id = fm.forum_id
LEFT JOIN avg_friends af ON af.forum_id = fm.forum_id
LEFT JOIN members_working_in_mod_city mwc ON mwc.forum_id = fm.forum_id
ORDER BY tm.total_members DESC
LIMIT 100
