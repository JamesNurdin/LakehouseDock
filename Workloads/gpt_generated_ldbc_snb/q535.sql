WITH forum_stats AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        mod.first_name AS moderator_first_name,
        mod.last_name AS moderator_last_name,
        COUNT(p.id) AS post_count,
        AVG(p.length) AS avg_post_length,
        COUNT(DISTINCT p.creator_person_id) AS distinct_creator_count,
        COUNT(DISTINCT wc.company_id) AS distinct_company_count,
        COUNT(DISTINCT org.type) AS distinct_company_type_count,
        COUNT(DISTINCT su.university_id) AS distinct_university_count,
        COUNT(DISTINCT pl.type) AS distinct_creator_city_type_count
    FROM forum f
    LEFT JOIN person mod
        ON f.moderator_person_id = mod.id
    LEFT JOIN post p
        ON p.container_forum_id = f.id
    LEFT JOIN person creator
        ON p.creator_person_id = creator.id
    LEFT JOIN person_work_at_company wc
        ON wc.person_id = creator.id
    LEFT JOIN organisation org
        ON wc.company_id = org.id
    LEFT JOIN person_study_at_university su
        ON su.person_id = creator.id
    LEFT JOIN place pl
        ON creator.location_city_id = pl.id
    GROUP BY f.id, f.title, mod.first_name, mod.last_name
)
SELECT
    forum_id,
    forum_title,
    moderator_first_name,
    moderator_last_name,
    post_count,
    avg_post_length,
    distinct_creator_count,
    distinct_company_count,
    distinct_company_type_count,
    distinct_university_count,
    distinct_creator_city_type_count
FROM forum_stats
ORDER BY post_count DESC
LIMIT 10
