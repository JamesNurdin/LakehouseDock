WITH forum_posts AS (
    SELECT
        f.id AS forum_id,
        f.title AS forum_title,
        f.creation_date AS forum_creation_date,
        f.moderator_person_id AS moderator_person_id,
        COUNT(p.id) AS post_count,
        AVG(p.length) AS avg_post_length
    FROM forum f
    LEFT JOIN post p ON p.container_forum_id = f.id
    GROUP BY f.id, f.title, f.creation_date, f.moderator_person_id
),
forum_members AS (
    SELECT
        fm.forum_id,
        COUNT(DISTINCT fm.person_id) AS member_count,
        COUNT(DISTINCT pt.tag_id) AS distinct_interest_tag_count,
        COUNT(DISTINCT su.university_id) AS distinct_university_count,
        COUNT(DISTINCT plc.comment_id) AS total_likes_by_members
    FROM forum_has_member_person fm
    LEFT JOIN person per ON per.id = fm.person_id
    LEFT JOIN person_has_interest_tag pt ON pt.person_id = per.id
    LEFT JOIN person_study_at_university su ON su.person_id = per.id
    LEFT JOIN person_likes_comment plc ON plc.person_id = per.id
    GROUP BY fm.forum_id
),
moderator_info AS (
    SELECT
        p.id AS moderator_person_id,
        p.first_name,
        p.last_name,
        p.email
    FROM person p
)
SELECT
    fp.forum_id,
    fp.forum_title,
    fp.forum_creation_date,
    fp.post_count,
    fp.avg_post_length,
    fm.member_count,
    fm.distinct_interest_tag_count,
    fm.distinct_university_count,
    fm.total_likes_by_members,
    mi.first_name AS moderator_first_name,
    mi.last_name AS moderator_last_name,
    mi.email AS moderator_email
FROM forum_posts fp
LEFT JOIN forum_members fm ON fm.forum_id = fp.forum_id
LEFT JOIN moderator_info mi ON mi.moderator_person_id = fp.moderator_person_id
ORDER BY fp.post_count DESC
LIMIT 20
