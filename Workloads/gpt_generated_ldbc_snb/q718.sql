WITH member_stats AS (
    SELECT
        fmp.forum_id,
        COUNT(*) AS total_members,
        SUM(CASE WHEN p_member.gender = 'male' THEN 1 ELSE 0 END) AS male_members,
        SUM(CASE WHEN p_member.gender = 'female' THEN 1 ELSE 0 END) AS female_members
    FROM forum_has_member_person fmp
    JOIN person p_member
        ON fmp.person_id = p_member.id
    GROUP BY fmp.forum_id
),

tag_stats AS (
    SELECT
        fht.forum_id,
        COUNT(DISTINCT fht.tag_id) AS distinct_tags
    FROM forum_has_tag_tag fht
    GROUP BY fht.forum_id
),

moderator_info AS (
    SELECT
        f.id AS forum_id,
        p_mod.id AS moderator_id,
        p_mod.first_name,
        p_mod.last_name
    FROM forum f
    JOIN person p_mod
        ON f.moderator_person_id = p_mod.id
)
SELECT
    f.id AS forum_id,
    f.title,
    CONCAT(m.first_name, ' ', m.last_name) AS moderator_name,
    ms.total_members,
    ms.male_members,
    ms.female_members,
    ts.distinct_tags,
    ROW_NUMBER() OVER (ORDER BY ms.total_members DESC) AS member_rank
FROM forum f
LEFT JOIN member_stats ms
    ON f.id = ms.forum_id
LEFT JOIN tag_stats ts
    ON f.id = ts.forum_id
LEFT JOIN moderator_info m
    ON f.id = m.forum_id
WHERE ms.total_members IS NOT NULL
ORDER BY ms.total_members DESC
