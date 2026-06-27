WITH person_friends AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT pk.person2_id) AS friend_count
    FROM person p
    LEFT JOIN person_knows_person pk ON pk.person1_id = p.id
    GROUP BY p.id
),
person_interests AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT pit.tag_id) AS interest_tag_count,
        COUNT(DISTINCT tc.id) AS interest_tag_class_count
    FROM person p
    LEFT JOIN person_has_interest_tag pit ON pit.person_id = p.id
    LEFT JOIN tag t ON t.id = pit.tag_id
    LEFT JOIN tag_class tc ON tc.id = t.type_tag_class_id
    GROUP BY p.id
),
person_posts AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT po.id) AS post_count,
        AVG(po.length) AS avg_post_length,
        COUNT(DISTINCT pt.tag_id) AS post_tag_count,
        COUNT(DISTINCT tc.id) AS post_tag_class_count
    FROM person p
    LEFT JOIN post po ON po.creator_person_id = p.id
    LEFT JOIN post_has_tag_tag pt ON pt.post_id = po.id
    LEFT JOIN tag t ON t.id = pt.tag_id
    LEFT JOIN tag_class tc ON tc.id = t.type_tag_class_id
    GROUP BY p.id
),
person_forums AS (
    SELECT
        p.id AS person_id,
        COUNT(DISTINCT fm.forum_id) AS membership_forum_count,
        COUNT(DISTINCT f.id) AS moderated_forum_count
    FROM person p
    LEFT JOIN forum_has_member_person fm ON fm.person_id = p.id
    LEFT JOIN forum f ON f.moderator_person_id = p.id
    GROUP BY p.id
)
SELECT
    p.id,
    p.first_name,
    p.last_name,
    p.gender,
    COALESCE(pf.friend_count, 0) AS friend_count,
    COALESCE(pi.interest_tag_count, 0) AS interest_tag_count,
    COALESCE(pi.interest_tag_class_count, 0) AS interest_tag_class_count,
    COALESCE(pp.post_count, 0) AS post_count,
    COALESCE(pp.avg_post_length, 0) AS avg_post_length,
    COALESCE(pp.post_tag_count, 0) AS post_tag_count,
    COALESCE(pp.post_tag_class_count, 0) AS post_tag_class_count,
    COALESCE(pfr.membership_forum_count, 0) AS membership_forum_count,
    COALESCE(pfr.moderated_forum_count, 0) AS moderated_forum_count
FROM person p
LEFT JOIN person_friends pf ON pf.person_id = p.id
LEFT JOIN person_interests pi ON pi.person_id = p.id
LEFT JOIN person_posts pp ON pp.person_id = p.id
LEFT JOIN person_forums pfr ON pfr.person_id = p.id
ORDER BY pp.post_count DESC NULLS LAST
LIMIT 20
