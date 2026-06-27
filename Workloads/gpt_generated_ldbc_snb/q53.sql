WITH forum_members AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(DISTINCT psu.university_id) AS distinct_universities,
        COUNT(DISTINCT pwc.company_id) AS distinct_companies
    FROM forum_has_member_person fm
    LEFT JOIN person p ON fm.person_id = p.id
    LEFT JOIN person_study_at_university psu ON p.id = psu.person_id
    LEFT JOIN person_work_at_company pwc ON p.id = pwc.person_id
    GROUP BY fm.forum_id
),
forum_posts AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM post p
    GROUP BY p.container_forum_id
),
forum_comments AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(DISTINCT c.id) AS comment_count,
        AVG(c.length) AS avg_comment_length
    FROM comment c
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
),
forum_comment_likes AS (
    SELECT
        p.container_forum_id AS forum_id,
        COUNT(*) AS comment_like_count
    FROM person_likes_comment plc
    JOIN comment c ON plc.comment_id = c.id
    JOIN post p ON c.parent_post_id = p.id
    GROUP BY p.container_forum_id
)
SELECT
    f.id AS forum_id,
    f.title,
    f.creation_date,
    mod.first_name AS moderator_first_name,
    mod.last_name AS moderator_last_name,
    mod_city.name AS moderator_city,
    fm.member_count,
    fm.distinct_universities,
    fm.distinct_companies,
    fp.post_count,
    fp.avg_post_length,
    fc.comment_count,
    fc.avg_comment_length,
    fcl.comment_like_count
FROM forum f
LEFT JOIN person mod ON f.moderator_person_id = mod.id
LEFT JOIN place mod_city ON mod.location_city_id = mod_city.id
LEFT JOIN forum_members fm ON fm.forum_id = f.id
LEFT JOIN forum_posts fp ON fp.forum_id = f.id
LEFT JOIN forum_comments fc ON fc.forum_id = f.id
LEFT JOIN forum_comment_likes fcl ON fcl.forum_id = f.id
ORDER BY f.id
LIMIT 10
