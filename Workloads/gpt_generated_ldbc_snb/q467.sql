WITH forum_members AS (
    SELECT
        f.id AS forum_id,
        p.id AS member_id,
        p.language AS member_language
    FROM forum f
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    JOIN person p
        ON p.id = fm.person_id
),
member_orgs AS (
    -- Organizations (companies or universities) where forum members work or study
    SELECT
        f.id AS forum_id,
        p.id AS member_id,
        pwac.company_id AS org_id
    FROM forum f
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    JOIN person p
        ON p.id = fm.person_id
    LEFT JOIN person_work_at_company pwac
        ON pwac.person_id = p.id
    UNION
    SELECT
        f.id AS forum_id,
        p.id AS member_id,
        psu.university_id AS org_id
    FROM forum f
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    JOIN person p
        ON p.id = fm.person_id
    LEFT JOIN person_study_at_university psu
        ON psu.person_id = p.id
),
members_agg AS (
    SELECT
        forum_id,
        COUNT(DISTINCT member_id) AS member_count,
        COUNT(DISTINCT member_language) AS distinct_member_languages
    FROM forum_members
    GROUP BY forum_id
),
orgs_agg AS (
    SELECT
        forum_id,
        COUNT(DISTINCT org_id) AS org_count
    FROM member_orgs
    GROUP BY forum_id
),
posts_agg AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT po.id) AS post_count,
        AVG(po.length) AS avg_post_length,
        COUNT(DISTINCT p_creator.language) AS distinct_creator_languages
    FROM forum f
    LEFT JOIN post po
        ON po.container_forum_id = f.id
    LEFT JOIN person p_creator
        ON p_creator.id = po.creator_person_id
    GROUP BY f.id
),
moderator_friends AS (
    SELECT
        f.id AS forum_id,
        COUNT(DISTINCT pkp.person2_id) AS moderator_friend_count
    FROM forum f
    JOIN person mod
        ON mod.id = f.moderator_person_id
    LEFT JOIN person_knows_person pkp
        ON pkp.person1_id = mod.id
    GROUP BY f.id
)
SELECT
    f.id AS forum_id,
    f.title AS forum_title,
    COALESCE(m.member_count, 0) AS member_count,
    COALESCE(m.distinct_member_languages, 0) AS distinct_member_languages,
    COALESCE(o.org_count, 0) AS org_count,
    COALESCE(pa.post_count, 0) AS post_count,
    pa.avg_post_length,
    COALESCE(pa.distinct_creator_languages, 0) AS distinct_creator_languages,
    COALESCE(mf.moderator_friend_count, 0) AS moderator_friend_count
FROM forum f
LEFT JOIN members_agg m
    ON m.forum_id = f.id
LEFT JOIN orgs_agg o
    ON o.forum_id = f.id
LEFT JOIN posts_agg pa
    ON pa.forum_id = f.id
LEFT JOIN moderator_friends mf
    ON mf.forum_id = f.id
ORDER BY member_count DESC
LIMIT 100
