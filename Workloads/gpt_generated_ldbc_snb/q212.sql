WITH
    friends_cte AS (
        SELECT
            p.id AS person_id,
            COUNT(DISTINCT pk.person2_id) AS friend_count
        FROM person p
        JOIN person_knows_person pk
            ON pk.person1_id = p.id
        GROUP BY p.id
    ),
    comments_cte AS (
        SELECT
            p.id AS person_id,
            COUNT(DISTINCT c.id) AS comment_count
        FROM person p
        JOIN comment c
            ON c.creator_person_id = p.id
        GROUP BY p.id
    ),
    likes_cte AS (
        SELECT
            p.id AS person_id,
            COUNT(DISTINCT plc.comment_id) AS like_count
        FROM person p
        JOIN person_likes_comment plc
            ON plc.person_id = p.id
        GROUP BY p.id
    ),
    forum_membership_cte AS (
        SELECT
            p.id AS person_id,
            COUNT(DISTINCT fhm.forum_id) AS forum_membership_count
        FROM person p
        JOIN forum_has_member_person fhm
            ON fhm.person_id = p.id
        GROUP BY p.id
    ),
    moderated_forums_cte AS (
        SELECT
            p.id AS person_id,
            COUNT(DISTINCT f.id) AS moderated_forum_count
        FROM person p
        JOIN forum f
            ON f.moderator_person_id = p.id
        GROUP BY p.id
    )
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    p.language,
    COALESCE(f.friend_count, 0) AS friend_count,
    COALESCE(c.comment_count, 0) AS comment_count,
    COALESCE(l.like_count, 0) AS like_count,
    COALESCE(m.forum_membership_count, 0) AS forum_membership_count,
    COALESCE(mod.moderated_forum_count, 0) AS moderated_forum_count
FROM person p
LEFT JOIN friends_cte f
    ON f.person_id = p.id
LEFT JOIN comments_cte c
    ON c.person_id = p.id
LEFT JOIN likes_cte l
    ON l.person_id = p.id
LEFT JOIN forum_membership_cte m
    ON m.person_id = p.id
LEFT JOIN moderated_forums_cte mod
    ON mod.person_id = p.id
ORDER BY like_count DESC
LIMIT 10
