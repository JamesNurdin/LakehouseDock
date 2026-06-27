WITH person_posts AS (
    SELECT
        p.id AS person_id,
        p.first_name,
        p.last_name,
        COUNT(DISTINCT po.id) AS post_count,
        AVG(po.length) AS avg_post_length
    FROM person p
    LEFT JOIN post po
        ON po.creator_person_id = p.id
    GROUP BY p.id, p.first_name, p.last_name
),
person_comments AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM person p
    LEFT JOIN comment c
        ON c.creator_person_id = p.id
    GROUP BY p.id
),
person_friends AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT pk.friend_id) AS friend_count
    FROM person p
    LEFT JOIN (
        SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
    ) pk
        ON pk.person_id = p.id
    GROUP BY p.id
),
person_likes_received AS (
    SELECT
        p.id AS person_id,
        COUNT(plp.person_id) AS likes_received
    FROM person p
    LEFT JOIN post po
        ON po.creator_person_id = p.id
    LEFT JOIN person_likes_post plp
        ON plp.post_id = po.id
    GROUP BY p.id
),
person_forum_membership AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT fmp.forum_id) AS forum_membership_count
    FROM person p
    LEFT JOIN forum_has_member_person fmp
        ON fmp.person_id = p.id
    GROUP BY p.id
)
SELECT
    pp.person_id,
    pp.first_name,
    pp.last_name,
    pp.post_count,
    pp.avg_post_length,
    pc.comment_count,
    pc.avg_comment_length,
    pf.friend_count,
    pl.likes_received,
    fm.forum_membership_count
FROM person_posts pp
LEFT JOIN person_comments pc
    ON pc.person_id = pp.person_id
LEFT JOIN person_friends pf
    ON pf.person_id = pp.person_id
LEFT JOIN person_likes_received pl
    ON pl.person_id = pp.person_id
LEFT JOIN person_forum_membership fm
    ON fm.person_id = pp.person_id
ORDER BY pp.post_count DESC, pl.likes_received DESC
LIMIT 20
