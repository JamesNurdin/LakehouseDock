WITH comment_stats AS (
    SELECT creator_person_id,
           COUNT(*) AS comment_count,
           AVG(length) AS avg_comment_length
    FROM comment
    GROUP BY creator_person_id
),
like_stats AS (
    SELECT person_id,
           COUNT(DISTINCT post_id) AS like_count
    FROM person_likes_post
    GROUP BY person_id
),
forum_mod_stats AS (
    SELECT moderator_person_id,
           COUNT(*) AS forum_moderated_count
    FROM forum
    GROUP BY moderator_person_id
),
interest_stats AS (
    SELECT person_id,
           COUNT(DISTINCT tag_id) AS interest_count
    FROM person_has_interest_tag
    GROUP BY person_id
),
work_stats AS (
    SELECT person_id,
           COUNT(DISTINCT company_id) AS work_company_count
    FROM person_work_at_company
    GROUP BY person_id
),
study_stats AS (
    SELECT person_id,
           COUNT(DISTINCT university_id) AS study_university_count
    FROM person_study_at_university
    GROUP BY person_id
),
friend_counts AS (
    SELECT person_id,
           COUNT(DISTINCT friend_id) AS friend_count
    FROM (
        SELECT person1_id AS person_id, person2_id AS friend_id FROM person_knows_person
        UNION ALL
        SELECT person2_id AS person_id, person1_id AS friend_id FROM person_knows_person
    ) f
    GROUP BY person_id
)
SELECT
    p.id AS person_id,
    p.first_name,
    p.last_name,
    p.gender,
    pl.name AS city_name,
    COALESCE(cs.comment_count, 0) AS comment_count,
    COALESCE(cs.avg_comment_length, 0) AS avg_comment_length,
    COALESCE(ls.like_count, 0) AS like_count,
    COALESCE(fm.forum_moderated_count, 0) AS forum_moderated_count,
    COALESCE(ints.interest_count, 0) AS interest_count,
    COALESCE(fc.friend_count, 0) AS friend_count,
    COALESCE(ws.work_company_count, 0) AS work_company_count,
    COALESCE(ss.study_university_count, 0) AS study_university_count
FROM person p
LEFT JOIN place pl ON p.location_city_id = pl.id
LEFT JOIN comment_stats cs ON p.id = cs.creator_person_id
LEFT JOIN like_stats ls ON p.id = ls.person_id
LEFT JOIN forum_mod_stats fm ON p.id = fm.moderator_person_id
LEFT JOIN interest_stats ints ON p.id = ints.person_id
LEFT JOIN friend_counts fc ON p.id = fc.person_id
LEFT JOIN work_stats ws ON p.id = ws.person_id
LEFT JOIN study_stats ss ON p.id = ss.person_id
ORDER BY comment_count DESC
LIMIT 100
