WITH forum_info AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date AS forum_creation_date,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name
    FROM forum f
    LEFT JOIN person mod
        ON f.moderator_person_id = mod.id
),
member_info AS (
    SELECT
        fhmp.forum_id,
        p.id AS member_id,
        p.gender,
        psu.university_id,
        psu.class_year
    FROM forum_has_member_person fhmp
    JOIN person p
        ON fhmp.person_id = p.id
    LEFT JOIN person_study_at_university psu
        ON p.id = psu.person_id
)
SELECT
    fi.forum_id,
    fi.title,
    fi.forum_creation_date,
    fi.moderator_first_name,
    fi.moderator_last_name,
    COUNT(DISTINCT mi.member_id) AS total_members,
    COUNT(DISTINCT CASE WHEN mi.gender = 'male' THEN mi.member_id END) AS male_members,
    COUNT(DISTINCT CASE WHEN mi.gender = 'female' THEN mi.member_id END) AS female_members,
    COUNT(DISTINCT CASE WHEN mi.gender NOT IN ('male', 'female') THEN mi.member_id END) AS other_gender_members,
    AVG(mi.class_year) AS avg_class_year,
    COUNT(DISTINCT CASE WHEN mi.university_id = 42 THEN mi.member_id END) AS members_at_university_42
FROM forum_info fi
LEFT JOIN member_info mi
    ON fi.forum_id = mi.forum_id
GROUP BY
    fi.forum_id,
    fi.title,
    fi.forum_creation_date,
    fi.moderator_first_name,
    fi.moderator_last_name
ORDER BY total_members DESC
LIMIT 100
