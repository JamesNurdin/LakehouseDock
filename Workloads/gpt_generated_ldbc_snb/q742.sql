WITH post_metrics AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT po.id) AS post_count,
        AVG(po.length) AS avg_post_length
    FROM person p
    LEFT JOIN post po
        ON po.creator_person_id = p.id
    GROUP BY p.id
),
comment_metrics AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM person p
    LEFT JOIN comment c
        ON c.creator_person_id = p.id
    GROUP BY p.id
),
likes_given_post AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT plp.post_id) AS likes_given_post_count
    FROM person p
    LEFT JOIN person_likes_post plp
        ON plp.person_id = p.id
    GROUP BY p.id
),
likes_given_comment AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT plc.comment_id) AS likes_given_comment_count
    FROM person p
    LEFT JOIN person_likes_comment plc
        ON plc.person_id = p.id
    GROUP BY p.id
),
likes_received_post AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT plp.person_id) AS likes_received_post_count
    FROM post po
    JOIN person_likes_post plp
        ON plp.post_id = po.id
    JOIN person p
        ON po.creator_person_id = p.id
    GROUP BY p.id
),
likes_received_comment AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT plc.person_id) AS likes_received_comment_count
    FROM comment c
    JOIN person_likes_comment plc
        ON plc.comment_id = c.id
    JOIN person p
        ON c.creator_person_id = p.id
    GROUP BY p.id
),
forum_membership AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT fmp.forum_id) AS forum_membership_count
    FROM person p
    LEFT JOIN forum_has_member_person fmp
        ON fmp.person_id = p.id
    GROUP BY p.id
),
interest_tags AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT pit.tag_id) AS interest_tag_count
    FROM person p
    LEFT JOIN person_has_interest_tag pit
        ON pit.person_id = p.id
    GROUP BY p.id
),
friend_counts AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT friend_id) AS friend_count
    FROM person p
    LEFT JOIN (
        SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
    ) pk
        ON pk.person_id = p.id
    GROUP BY p.id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    COALESCE(pm.post_count, 0) AS post_count,
    COALESCE(pm.avg_post_length, 0) AS avg_post_length,
    COALESCE(cm.comment_count, 0) AS comment_count,
    COALESCE(cm.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(lgp.likes_given_post_count, 0) AS likes_given_post_count,
    COALESCE(lgc.likes_given_comment_count, 0) AS likes_given_comment_count,
    COALESCE(lrp.likes_received_post_count, 0) AS likes_received_post_count,
    COALESCE(lrc.likes_received_comment_count, 0) AS likes_received_comment_count,
    COALESCE(fm.forum_membership_count, 0) AS forum_membership_count,
    COALESCE(it.interest_tag_count, 0) AS interest_tag_count,
    COALESCE(fc.friend_count, 0) AS friend_count
FROM person p
LEFT JOIN post_metrics pm
    ON pm.person_id = p.id
LEFT JOIN comment_metrics cm
    ON cm.person_id = p.id
LEFT JOIN likes_given_post lgp
    ON lgp.person_id = p.id
LEFT JOIN likes_given_comment lgc
    ON lgc.person_id = p.id
LEFT JOIN likes_received_post lrp
    ON lrp.person_id = p.id
LEFT JOIN likes_received_comment lrc
    ON lrc.person_id = p.id
LEFT JOIN forum_membership fm
    ON fm.person_id = p.id
LEFT JOIN interest_tags it
    ON it.person_id = p.id
LEFT JOIN friend_counts fc
    ON fc.person_id = p.id
ORDER BY p.id
LIMIT 100
