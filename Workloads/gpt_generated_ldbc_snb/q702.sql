-- Top 5 forums by member count with moderator info and gender distribution
WITH forum_member_aggregates AS (
    SELECT
        f.id,
        f.title,
        f.creation_date,
        mod.first_name,
        mod.last_name,
        mod.gender AS moderator_gender,
        COUNT(DISTINCT fm.person_id) AS member_count,
        SUM(CASE WHEN p.gender = 'male'   THEN 1 ELSE 0 END) AS male_member_count,
        SUM(CASE WHEN p.gender = 'female' THEN 1 ELSE 0 END) AS female_member_count
    FROM forum f
    JOIN forum_has_member_person fm
        ON fm.forum_id = f.id
    JOIN person p
        ON p.id = fm.person_id
    LEFT JOIN person mod
        ON mod.id = f.moderator_person_id
    GROUP BY f.id, f.title, f.creation_date, mod.first_name, mod.last_name, mod.gender
)
SELECT
    id,
    title,
    creation_date,
    first_name  AS moderator_first_name,
    last_name   AS moderator_last_name,
    moderator_gender,
    member_count,
    male_member_count,
    female_member_count,
    (male_member_count * 100.0)   / NULLIF(member_count, 0) AS male_percent,
    (female_member_count * 100.0) / NULLIF(member_count, 0) AS female_percent
FROM forum_member_aggregates
ORDER BY member_count DESC
LIMIT 5
