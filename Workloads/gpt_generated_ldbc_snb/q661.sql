WITH
    friends AS (
        SELECT
            pk.person_id,
            COUNT(DISTINCT pk.friend_id) AS friend_count
        FROM (
            SELECT person1_id AS person_id, person2_id AS friend_id
            FROM person_knows_person
            UNION ALL
            SELECT person2_id AS person_id, person1_id AS friend_id
            FROM person_knows_person
        ) pk
        GROUP BY pk.person_id
    ),
    interests AS (
        SELECT
            person_id,
            COUNT(DISTINCT tag_id) AS interest_count
        FROM person_has_interest_tag
        GROUP BY person_id
    ),
    comments AS (
        SELECT
            creator_person_id AS person_id,
            COUNT(*) AS comment_count
        FROM comment
        GROUP BY creator_person_id
    ),
    likes AS (
        SELECT
            person_id,
            COUNT(DISTINCT post_id) AS likes_count
        FROM person_likes_post
        GROUP BY person_id
    ),
    companies AS (
        SELECT
            person_id,
            COUNT(DISTINCT company_id) AS company_count
        FROM person_work_at_company
        GROUP BY person_id
    ),
    forum_memberships AS (
        SELECT
            person_id,
            COUNT(DISTINCT forum_id) AS forum_membership_count
        FROM forum_has_member_person
        GROUP BY person_id
    ),
    moderated_forums AS (
        SELECT
            moderator_person_id AS person_id,
            COUNT(DISTINCT id) AS moderated_forum_count
        FROM forum
        GROUP BY moderator_person_id
    ),
    person_city AS (
        SELECT
            p.id AS person_id,
            p.first_name,
            p.last_name,
            pl.name AS city_name
        FROM person p
        LEFT JOIN place pl ON p.location_city_id = pl.id
    )
SELECT
    pc.person_id,
    pc.first_name,
    pc.last_name,
    pc.city_name,
    COALESCE(f.friend_count, 0)               AS friend_count,
    COALESCE(i.interest_count, 0)            AS interest_count,
    COALESCE(c.comment_count, 0)             AS comment_count,
    COALESCE(l.likes_count, 0)               AS likes_count,
    COALESCE(comp.company_count, 0)          AS company_count,
    COALESCE(fm.forum_membership_count, 0)   AS forum_membership_count,
    COALESCE(mf.moderated_forum_count, 0)    AS moderated_forum_count
FROM person_city pc
LEFT JOIN friends f ON pc.person_id = f.person_id
LEFT JOIN interests i ON pc.person_id = i.person_id
LEFT JOIN comments c ON pc.person_id = c.person_id
LEFT JOIN likes l ON pc.person_id = l.person_id
LEFT JOIN companies comp ON pc.person_id = comp.person_id
LEFT JOIN forum_memberships fm ON pc.person_id = fm.person_id
LEFT JOIN moderated_forums mf ON pc.person_id = mf.person_id
ORDER BY pc.person_id
LIMIT 100
