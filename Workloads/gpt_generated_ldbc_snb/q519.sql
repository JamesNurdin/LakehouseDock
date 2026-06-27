WITH member_info AS (
    SELECT
        fhm.forum_id,
        p.id AS person_id
    FROM forum_has_member_person fhm
    JOIN person p ON fhm.person_id = p.id
),
connections AS (
    SELECT
        person_id,
        COUNT(DISTINCT friend_id) AS connection_count
    FROM (
        SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
    ) AS all_friends
    GROUP BY person_id
),
post_stats AS (
    SELECT
        mi.forum_id,
        COUNT(p.id) AS total_posts,
        SUM(p.length) AS total_post_length,
        AVG(p.length) AS avg_post_length
    FROM member_info mi
    JOIN post p ON p.creator_person_id = mi.person_id
    GROUP BY mi.forum_id
),
member_university AS (
    SELECT
        mi.forum_id,
        mi.person_id,
        psu.university_id
    FROM member_info mi
    LEFT JOIN person_study_at_university psu ON psu.person_id = mi.person_id
)
SELECT
    mi.forum_id,
    COUNT(DISTINCT mi.person_id) AS member_count,
    COALESCE(ps.total_posts, 0) AS total_posts_by_members,
    COALESCE(ps.total_post_length, 0) AS total_post_length_by_members,
    COALESCE(ps.avg_post_length, 0) AS avg_post_length_by_members,
    AVG(COALESCE(c.connection_count, 0)) AS avg_connections_per_member,
    COUNT(DISTINCT CASE WHEN mu.university_id = 42 THEN mu.person_id END) AS members_at_university_42
FROM member_info mi
LEFT JOIN connections c ON c.person_id = mi.person_id
LEFT JOIN member_university mu ON mu.forum_id = mi.forum_id AND mu.person_id = mi.person_id
LEFT JOIN post_stats ps ON ps.forum_id = mi.forum_id
GROUP BY
    mi.forum_id,
    ps.total_posts,
    ps.total_post_length,
    ps.avg_post_length
ORDER BY total_posts_by_members DESC
LIMIT 100
