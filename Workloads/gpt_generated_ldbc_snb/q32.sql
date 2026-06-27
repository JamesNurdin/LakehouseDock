WITH member_counts AS (
    SELECT
        fhm.forum_id,
        COUNT(DISTINCT fhm.person_id) AS member_count,
        COUNT(DISTINCT CASE WHEN p.gender = 'male' THEN fhm.person_id END) AS male_member_count,
        COUNT(DISTINCT CASE WHEN p.gender = 'female' THEN fhm.person_id END) AS female_member_count
    FROM forum_has_member_person fhm
    JOIN person p ON fhm.person_id = p.id
    GROUP BY fhm.forum_id
),

tag_counts AS (
    SELECT
        fht.forum_id,
        COUNT(DISTINCT fht.tag_id) AS tag_count
    FROM forum_has_tag_tag fht
    GROUP BY fht.forum_id
),

post_stats AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_creator_count,
        COUNT(DISTINCT CASE WHEN per.gender = 'male' THEN p.creator_person_id END) AS male_creator_count,
        COUNT(DISTINCT CASE WHEN per.gender = 'female' THEN p.creator_person_id END) AS female_creator_count
    FROM post p
    JOIN person per ON p.creator_person_id = per.id
    GROUP BY p.container_forum_id
),

moderators AS (
    SELECT
        f.id AS forum_id,
        f.title,
        f.creation_date,
        per.first_name AS moderator_first_name,
        per.last_name AS moderator_last_name
    FROM forum f
    JOIN person per ON f.moderator_person_id = per.id
)

SELECT
    m.forum_id,
    m.title,
    m.creation_date,
    m.moderator_first_name,
    m.moderator_last_name,
    COALESCE(mc.member_count, 0) AS member_count,
    COALESCE(mc.male_member_count, 0) AS male_member_count,
    COALESCE(mc.female_member_count, 0) AS female_member_count,
    COALESCE(tc.tag_count, 0) AS tag_count,
    COALESCE(ps.post_count, 0) AS post_count,
    ps.avg_post_length,
    COALESCE(ps.distinct_creator_count, 0) AS distinct_creator_count,
    COALESCE(ps.male_creator_count, 0) AS male_creator_count,
    COALESCE(ps.female_creator_count, 0) AS female_creator_count
FROM moderators m
LEFT JOIN member_counts mc ON m.forum_id = mc.forum_id
LEFT JOIN tag_counts tc ON m.forum_id = tc.forum_id
LEFT JOIN post_stats ps ON m.forum_id = ps.forum_id
ORDER BY COALESCE(ps.post_count, 0) DESC, m.forum_id
